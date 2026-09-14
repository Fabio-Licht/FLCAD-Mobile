// Included inside the shared source implementation namespace.
struct StepPrepared {
  std::string name, unit;
  occ_step_metadata_v1 metadata{};
};
#ifdef FLCAD_OCC_TESTING
thread_local uint64_t step_readstream_calls = 0, step_transfer_calls = 0;
#endif
bool step_valid_utf8(const std::string &text) {
  for (size_t i = 0; i < text.size();) {
    uint32_t c = static_cast<unsigned char>(text[i++]);
    if (c < 0x80)
      continue;
    uint32_t n = 0, minimum = 0;
    if (c >= 0xc2 && c <= 0xdf) {
      n = 1;
      minimum = 0x80;
      c &= 0x1f;
    } else if (c >= 0xe0 && c <= 0xef) {
      n = 2;
      minimum = 0x800;
      c &= 0xf;
    } else if (c >= 0xf0 && c <= 0xf4) {
      n = 3;
      minimum = 0x10000;
      c &= 7;
    } else
      return false;
    if (n > text.size() - i)
      return false;
    while (n--) {
      const auto next = static_cast<unsigned char>(text[i++]);
      if ((next & 0xc0) != 0x80)
        return false;
      c = (c << 6) | (next & 0x3f);
    }
    if (c < minimum || c > 0x10ffff || (c >= 0xd800 && c <= 0xdfff))
      return false;
  }
  return true;
}
// Strict Part21 framing gate, not a substitute for OCCT semantic validation.
// Reads the same admitted source, then rewinds it. No whole-input allocation.
class StepLex {
  std::istream &stream;
  SourceInput &input;
  const occ_read_limits_v1 &limits;
  uint64_t tokens = 0, line = 0, characters = 0;
  int get() {
    int c = stream.get();
    if (input.failed())
      throw SourceFailure{};
    if (c == EOF)
      return c;
    if (++characters % 4096 == 0)
      input.check(0);
    if (c == '\n')
      line = 0;
    else if (++line > limits.max_line_bytes)
      input.stop(OCC_READ_LIMIT, "STEP line limit");
    if (c < 32 && c != '\n' && c != '\r' && c != '\t')
      input.stop(OCC_READ_FORMAT, "Invalid STEP transport control");
    return c;
  }
  void append(std::string &word, int c) {
    if (word.size() >= limits.max_token_bytes)
      input.stop(OCC_READ_LIMIT, "STEP token/string limit");
    word += static_cast<char>(c);
  }

public:
  uint64_t begin = 0;
  uint64_t end() const { return characters; }
  StepLex(std::istream &s, SourceInput &i, const occ_read_limits_v1 &l)
      : stream(s), input(i), limits(l) {}
  std::string next() {
    int c;
    for (;;) {
      c = get();
      if (c == EOF)
        return {};
      if (c == ' ' || c == '\t' || c == '\r' || c == '\n')
        continue;
      if (c != '/')
        break;
      if (get() != '*')
        input.stop(OCC_READ_FORMAT, "Invalid STEP comment");
      int prior = 0;
      for (;;) {
        c = get();
        if (c == EOF)
          input.stop(OCC_READ_TRUNCATED, "Unterminated STEP comment");
        if (prior == '*' && c == '/')
          break;
        prior = c;
      }
    }
    if (++tokens > limits.max_tokens)
      input.stop(OCC_READ_LIMIT, "STEP token count limit");
    std::string word;
    begin = characters - 1;
    if (c > 126)
      input.stop(OCC_READ_FORMAT, "Non-ASCII STEP syntax");
    append(word, c);
    if (c == '\'') {
      for (;;) {
        c = get();
        if (c == EOF)
          input.stop(OCC_READ_TRUNCATED, "Unterminated STEP string");
        append(word, c);
        if (c == '\'') {
          if (stream.peek() != '\'')
            break;
          append(word, get());
        }
      }
      if (!step_valid_utf8(word))
        input.stop(OCC_READ_FORMAT, "Invalid STEP UTF-8 transport string");
      return "'"; // content must never be interpreted as a keyword
    }
    if (std::strchr("(),;=$*", c))
      return word;
    if (c == '"')
      input.stop(OCC_READ_FORMAT, "Binary STEP parameters unsupported");
    while (stream.peek() != EOF) {
      const int p = stream.peek();
      if (!(std::isalnum(static_cast<unsigned char>(p)) ||
            std::strchr("_-+.#", p)))
        break;
      append(word, get());
    }
    if (word[0] == '#') {
      uint64_t label = 0;
      const auto parsed =
          std::from_chars(word.data() + 1, word.data() + word.size(), label);
      if (parsed.ec != std::errc() || parsed.ptr != word.data() + word.size() ||
          !label || label > INT_MAX)
        input.stop(OCC_READ_LIMIT, "STEP entity label range");
    }
    if (word.find("EXTERN") != std::string::npos || word == "DOCUMENT_FILE" ||
        word == "APPLIED_DOCUMENT_REFERENCE" ||
        word == "PRODUCT_DEFINITION_WITH_ASSOCIATED_DOCUMENTS")
      input.stop(OCC_READ_FORMAT, "STEP external references unsupported");
    if (word == "SURFACE_STYLE_TRANSPARENT")
      input.stop(OCC_READ_FORMAT, "STEP transparency unsupported");
    return word;
  }
  void expect(const char *expected) {
    const auto actual = next();
    if (actual != expected)
      input.stop(actual.empty() ? OCC_READ_TRUNCATED : OCC_READ_FORMAT,
                 "Invalid or incomplete STEP framing");
  }
  void parameters(bool terminated = true) {
    expect("(");
    uint32_t depth = 1;
    while (depth) {
      const auto word = next();
      if (word.empty())
        input.stop(OCC_READ_TRUNCATED, "Unterminated STEP record");
      if (word == "(" && ++depth > 256)
        input.stop(OCC_READ_LIMIT, "STEP nesting limit");
      if (word == ")")
        --depth;
      if (word == ";" || word == "ENDSEC")
        input.stop(OCC_READ_FORMAT, "Incomplete STEP parameters");
    }
    if (terminated)
      expect(";");
  }
};

// Compatibility v1 is an AST rule for exactly one known zero-dimensional
// steradian unit, not a text substitution or a general error-recovery reader.
std::string step_compatibility(std::istream &source, SourceInput &input,
                               const occ_read_limits_v1 &limits,
                               int expected_label) {
  if (input.length() > 64 * 1024 * 1024)
    input.stop(OCC_READ_LIMIT, "STEP compatibility memory limit");
  source.clear();
  source.seekg(0);
  std::string bytes(static_cast<size_t>(input.length()), '\0');
  read_exact(source, input, bytes.data(), bytes.size());
  // CAF rehashes the admitted original against its sealed SHA-256. The retry
  // buffer never becomes the source identity and never touches the original.
  input.check(1);
  std::istringstream scan(bytes);
  StepLex lex(scan, input, limits);
  for (;;) {
    const auto word = lex.next();
    if (word == "DATA")
      break;
    if (word.empty())
      input.stop(OCC_READ_FORMAT, "STEP compatibility signature mismatch");
  }
  lex.expect(";");
  uint32_t dimension_label = 0;
  std::map<uint32_t, bool> dimensions;
  size_t patch_begin = 0, patch_end = 0;
  int candidates = 0;
  for (;;) {
    const auto id = lex.next();
    if (id == "ENDSEC")
      break;
    if (id.empty())
      input.stop(OCC_READ_FORMAT, "STEP compatibility signature mismatch");
    uint32_t label = 0;
    std::from_chars(id.data() + 1, id.data() + id.size(), label);
    lex.expect("=");
    const auto type = lex.next();
    const auto start = lex.begin;
    if (type != "(") {
      if (type == "DIMENSIONAL_EXPONENTS") {
        lex.expect("(");
        bool zero = true;
        for (int i = 0; i < 7; ++i) {
          const auto number = lex.next();
          double value = 1;
          auto parsed = std::from_chars(number.data(),
                                        number.data() + number.size(), value);
          zero &= parsed.ec == std::errc() &&
                  parsed.ptr == number.data() + number.size() && value == 0;
          if (i != 6)
            lex.expect(",");
        }
        lex.expect(")");
        lex.expect(";");
        dimensions.emplace(label, zero);
      } else
        lex.parameters();
      continue;
    }
    std::vector<std::pair<std::string, std::vector<std::string>>> parts;
    bool bounded = true;
    size_t token_count = 0;
    for (;;) {
      auto name = lex.next();
      if (name == ")")
        break;
      lex.expect("(");
      std::vector<std::string> parameters;
      int depth = 1;
      while (depth) {
        auto token = lex.next();
        if (token.empty())
          input.stop(OCC_READ_TRUNCATED, "Unterminated STEP record");
        if (token == "(")
          ++depth;
        if (token == ")")
          --depth;
        if (depth && ++token_count <= 64)
          parameters.push_back(token);
        if (token_count > 64)
          bounded = false;
      }
      if (parts.size() < 4)
        parts.emplace_back(name, parameters);
      else
        bounded = false;
    }
    const auto finish = lex.end();
    lex.expect(";");
    if (static_cast<int>(label) != expected_label)
      continue;
    if (!bounded || parts.size() != 3 || parts[0].first != "NAMED_UNIT" ||
        parts[0].second.size() != 1 || parts[0].second[0].empty() ||
        parts[0].second[0][0] != '#' || parts[1].first != "SOLID_ANGLE_UNIT" ||
        !parts[1].second.empty() || parts[2].first != "SI_UNIT" ||
        parts[2].second != std::vector<std::string>{"$", ",", ".STERADIAN."})
      input.stop(OCC_READ_FORMAT, "STEP compatibility signature mismatch");
    const auto &reference = parts[0].second[0];
    std::from_chars(reference.data() + 1, reference.data() + reference.size(),
                    dimension_label);
    ++candidates;
    patch_begin = start;
    patch_end = finish;
  }
  if (candidates != 1 || !dimensions.count(dimension_label) ||
      !dimensions.at(dimension_label))
    input.stop(OCC_READ_FORMAT, "STEP compatibility ambiguous dimensions");
  // Splice a parsed entity span. All other bytes, strings and comments retain
  // their original encoding, including text resembling this unit signature.
  std::string normalized = bytes.substr(0, patch_begin);
  normalized += "(NAMED_UNIT(*) SI_UNIT($,.STERADIAN.) SOLID_ANGLE_UNIT())";
  normalized.append(bytes, patch_end, std::string::npos);
  return normalized;
}
uint64_t step_frame(std::istream &s, SourceInput &input,
                    const occ_read_limits_v1 &limits) {
  StepLex lex(s, input, limits);
  lex.expect("ISO-10303-21");
  lex.expect(";");
  lex.expect("HEADER");
  lex.expect(";");
  for (const char *header : {"FILE_DESCRIPTION", "FILE_NAME", "FILE_SCHEMA"}) {
    lex.expect(header);
    lex.parameters();
  }
  lex.expect("ENDSEC");
  lex.expect(";");
  lex.expect("DATA");
  lex.expect(";");
  uint64_t entities = 0;
  std::unordered_set<uint32_t> labels;
  for (;;) {
    const auto id = lex.next();
    if (id == "ENDSEC")
      break;
    if (id.empty())
      input.stop(OCC_READ_TRUNCATED, "Missing STEP DATA terminator");
    if (id.size() < 2 || id[0] != '#' ||
        !std::all_of(id.begin() + 1, id.end(),
                     [](char c) { return c >= '0' && c <= '9'; }))
      input.stop(OCC_READ_FORMAT, "Invalid STEP entity label");
    if (++entities > limits.max_topology)
      input.stop(OCC_READ_LIMIT, "STEP entity limit");
    uint32_t label = 0;
    std::from_chars(id.data() + 1, id.data() + id.size(), label);
    if (!labels.insert(label).second)
      input.stop(OCC_READ_FORMAT, "STEP duplicate entity label");
    lex.expect("=");
    const auto type = lex.next();
    if (type == "(") { // complex entity: (TYPE(...) TYPE(...))
      for (;;) {
        const auto part = lex.next();
        if (part == ")")
          break;
        if (part.empty() || !std::isupper(static_cast<unsigned char>(part[0])))
          input.stop(OCC_READ_FORMAT, "Invalid STEP complex entity");
        lex.parameters(false);
      }
      lex.expect(";");
    } else {
      if (type.empty() || !std::isupper(static_cast<unsigned char>(type[0])))
        input.stop(OCC_READ_FORMAT, "Invalid STEP entity type");
      lex.parameters();
    }
  }
  lex.expect(";");
  lex.expect("END-ISO-10303-21");
  lex.expect(";");
  if (!lex.next().empty())
    input.stop(OCC_READ_FORMAT, "STEP trailing content");
  if (!entities)
    input.stop(OCC_READ_FORMAT, "Empty STEP DATA");
  s.clear();
  s.seekg(0);
  return entities;
}
void step_checks(Interface_CheckIterator checks, SourceInput &input,
                 const char *message) {
  for (checks.Start(); checks.More(); checks.Next()) {
    if (checks.Value()->NbFails()) {
#ifndef NDEBUG
      // DynamicType names are OCCT-owned schema symbols, never STEP values.
      const auto entity = checks.Value()->Entity();
      const char *type =
          entity.IsNull() ? "model" : entity->DynamicType()->Name();
      std::string failure = checks.Value()->CFail(1);
      std::transform(
          failure.begin(), failure.end(), failure.begin(),
          [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
      const char *category =
          failure.find("prefix") != std::string::npos      ? "unit.prefix"
          : failure.find("dimension") != std::string::npos ? "unit.dimensions"
          : failure.find("name") != std::string::npos      ? "unit.name"
          : failure.find("count") != std::string::npos     ? "parameter.count"
          : failure.find("parameter") != std::string::npos ? "parameter.invalid"
                                                           : "model.invalid";
      std::cerr << "[managed-step.native] check_failure schema_type=" << type
                << " category=" << category
                << " count=" << checks.Value()->NbFails() << '\n';
#endif
      input.stop(OCC_READ_FORMAT, message);
    }
  }
}
std::string step_utf8(const TCollection_ExtendedString &value,
                      SourceInput &input) {
  const int n = value.LengthOfCString();
  if (n < 0 || n > 4096)
    input.stop(OCC_READ_LIMIT, "STEP metadata string limit");
  std::string result(static_cast<size_t>(n) + 1, '\0');
  char *dst = result.data();
  if (value.ToUTF8CString(dst) != n)
    input.stop(OCC_READ_FORMAT, "Invalid STEP UTF-8 length");
  result.resize(n);
  // Reject embedded NUL, control characters and unpaired UTF-16 surrogates.
  for (int i = 1; i <= value.Length(); ++i) {
    const auto c = value.Value(i);
    if (c < 32 || c == 127)
      input.stop(OCC_READ_FORMAT, "Invalid STEP metadata control");
    if (c >= 0xd800 && c <= 0xdbff) {
      if (++i > value.Length() || value.Value(i) < 0xdc00 ||
          value.Value(i) > 0xdfff)
        input.stop(OCC_READ_FORMAT, "Invalid STEP Unicode surrogate");
    } else if (c >= 0xdc00 && c <= 0xdfff)
      input.stop(OCC_READ_FORMAT, "Invalid STEP Unicode surrogate");
  }
  return result;
}
TopoDS_Shape read_step(std::istream &s, SourceInput &input,
                       const occ_read_limits_v1 &limits,
                       StepPrepared &prepared) {
  const auto framed_entities = step_frame(s, input, limits);
  input.check(0);
  STEPCAFControl_Reader reader;
  reader.SetColorMode(true);
  reader.SetNameMode(true);
  reader.SetLayerMode(false);
  reader.SetPropsMode(false);
  reader.SetMetaMode(false);
  reader.SetProductMetaMode(false);
  reader.SetSHUOMode(false);
  reader.SetGDTMode(false);
  reader.SetMatMode(false);
  reader.SetViewMode(false);
#ifdef FLCAD_OCC_TESTING
  ++step_readstream_calls;
#endif
  if (reader.ReadStream("caf-step-source", s) != IFSelect_RetDone) {
    if (input.failed())
      throw SourceFailure{};
    input.stop(OCC_READ_FORMAT, "STEP ReadStream failed");
  }
  if (input.failed())
    throw SourceFailure{};
  input.check(0);
  auto &basic = reader.ChangeReader();
  auto model = basic.StepModel();
  if (model.IsNull() || model->NbEntities() > limits.max_topology)
    input.stop(OCC_READ_LIMIT, "STEP model entity limit");
  if (static_cast<uint64_t>(model->NbEntities()) != framed_entities)
    input.stop(OCC_READ_FORMAT, "STEP incomplete model load");
  if (model->SourceCodePage() != Resource_FormatType_UTF8)
    input.stop(OCC_READ_FORMAT, "STEP requires UTF-8 names configuration");
  auto checks = basic.WS()->ModelCheckList(true);
  int compatible_label = 0, failures = 0;
  bool recognized = true;
  for (checks.Start(); checks.More(); checks.Next()) {
    const auto check = checks.Value();
    if (!check->NbFails())
      continue;
    ++failures;
    const auto entity = check->Entity();
    if (entity.IsNull() ||
        entity->DynamicType() !=
            STANDARD_TYPE(StepBasic_SiUnitAndSolidAngleUnit) ||
        check->NbFails() != 1 ||
        std::string(check->CFail(1)) !=
            "Count of Parameters is not 2 for si_unit")
      recognized = false;
    else
      compatible_label = model->IdentLabel(entity);
  }
  uint32_t normalizations = 0;
  if (failures == 1 && recognized && compatible_label > 0) {
    auto normalized = step_compatibility(s, input, limits, compatible_label);
    input.check(0);
    // Fresh reader and work session: no partially loaded entity is reused.
    STEPCAFControl_Reader retry;
    retry.SetColorMode(true);
    retry.SetNameMode(true);
    retry.SetLayerMode(false);
    retry.SetPropsMode(false);
    retry.SetMetaMode(false);
    retry.SetProductMetaMode(false);
    retry.SetSHUOMode(false);
    retry.SetGDTMode(false);
    retry.SetMatMode(false);
    retry.SetViewMode(false);
    std::istringstream stream(normalized);
    if (step_frame(stream, input, limits) != framed_entities)
      input.stop(OCC_READ_FORMAT, "STEP compatibility signature mismatch");
#ifdef FLCAD_OCC_TESTING
    ++step_readstream_calls;
#endif
    if (retry.ReadStream("caf-step-compatibility-v1", stream) !=
        IFSelect_RetDone)
      input.stop(OCC_READ_FORMAT, "STEP compatibility ReadStream failed");
    input.check(1);
    step_checks(retry.ChangeReader().WS()->ModelCheckList(true), input,
                "STEP model validation failed");
    reader = retry;
    normalizations = 3;
    model = reader.ChangeReader().StepModel();
    if (model.IsNull() ||
        static_cast<uint64_t>(model->NbEntities()) != framed_entities ||
        model->SourceCodePage() != Resource_FormatType_UTF8)
      input.stop(OCC_READ_FORMAT, "STEP incomplete model load");
  } else
    step_checks(checks, input, "STEP model validation failed");
  auto &validated = reader.ChangeReader();
  STEPConstruct_ExternRefs refs(validated.WS());
  refs.LoadExternRefs();
  if (refs.NbExternRefs())
    input.stop(OCC_READ_FORMAT, "STEP external references unsupported");
  int products = 0, definitions = 0;
  double declared = 0;
  for (int i = 1; i <= model->NbEntities(); ++i) {
    if (i % 128 == 1)
      input.check(0);
    const auto entity = model->Value(i);
    if (entity.IsNull() || model->IsUnknownEntity(i) || model->IsErrorEntity(i))
      input.stop(OCC_READ_FORMAT, "STEP unknown or invalid entity");
    if (entity->IsKind(STANDARD_TYPE(StepBasic_Product)))
      ++products;
    if (entity->IsKind(STANDARD_TYPE(StepBasic_ProductDefinition)))
      ++definitions;
    if (entity->IsKind(STANDARD_TYPE(StepBasic_ProductDefinitionRelationship)))
      input.stop(OCC_READ_FORMAT,
                 "STEP assembly/component relationship unsupported");
    occ::handle<StepRepr_GlobalUnitAssignedContext> context =
        occ::down_cast<StepRepr_GlobalUnitAssignedContext>(entity);
    if (auto combined = occ::down_cast<
            StepGeom_GeomRepContextAndGlobUnitAssCtxAndGlobUncertaintyAssCtx>(
            entity);
        !combined.IsNull())
      context = combined->GlobalUnitAssignedContext();
    if (auto combined = occ::down_cast<
            StepGeom_GeometricRepresentationContextAndGlobalUnitAssignedContext>(
            entity);
        !combined.IsNull())
      context = combined->GlobalUnitAssignedContext();
    if (!context.IsNull()) {
      STEPConstruct_UnitContext units;
      if (units.ComputeFactors(context) || !units.LengthDone())
        input.stop(OCC_READ_FORMAT, "STEP length unit unresolved");
      const double scale = units.LengthFactor() * 0.001; // OCCT factor in mm
      if (!std::isfinite(scale) || scale <= 0 ||
          (declared && std::abs(declared - scale) > declared * 1e-12))
        input.stop(OCC_READ_FORMAT, "STEP incompatible length units");
      declared = scale;
    }
  }
  if (products != 1 || definitions != 1 || validated.NbRootsForTransfer() != 1)
    input.stop(OCC_READ_FORMAT, "STEP requires one product and one root");
  NCollection_Sequence<TCollection_AsciiString> length, angle, solid_angle;
  validated.FileUnits(length, angle, solid_angle);
  if (length.Length() != 1 || !declared)
    input.stop(OCC_READ_FORMAT, "STEP requires one declared length unit");
  prepared.unit = length.Value(1).ToCString();
  if (prepared.unit.empty() || prepared.unit.size() > 256 ||
      !std::all_of(prepared.unit.begin(), prepared.unit.end(),
                   [](char c) { return c >= 32 && c <= 126; }))
    input.stop(OCC_READ_FORMAT, "Invalid STEP unit name");
  occ::handle<TDocStd_Document> doc = new TDocStd_Document("BinXCAF");
  // Force resolved geometry into mm, independent of process global defaults.
  XCAFDoc_DocumentTool::SetLengthUnit(doc, 0.001);
  occ::handle<SourceProgress> progress = new SourceProgress(input);
#ifdef FLCAD_OCC_TESTING
  ++step_transfer_calls;
#endif
  const bool transferred = reader.Transfer(doc, progress->Start());
  if (input.failed())
    throw SourceFailure{};
  input.check(0);
  if (progress->unexpected_thread)
    input.stop(OCC_READ_SOURCE, "Unexpected STEP progress thread");
  if (!transferred)
    input.stop(OCC_READ_GEOMETRY, "STEP transfer incomplete");
  step_checks(validated.WS()->TransferReader()->LastCheckList(), input,
              "STEP transfer validation failed");
  auto shapes_tool = XCAFDoc_DocumentTool::ShapeTool(doc->Main());
  NCollection_Sequence<TDF_Label> roots;
  shapes_tool->GetFreeShapes(roots);
  if (roots.Length() != 1 || shapes_tool->IsAssembly(roots.Value(1)) ||
      shapes_tool->IsReference(roots.Value(1)) ||
      !reader.ExternFiles().IsEmpty())
    input.stop(OCC_READ_FORMAT, "STEP non-single-part XDE document");
  const auto root = roots.Value(1);
  const auto shape = shapes_tool->GetShape(root);
  if (shape.ShapeType() != TopAbs_SOLID)
    input.stop(OCC_READ_GEOMETRY, "STEP-1A0 requires one solid");
  input.phase(OCC_READ_VALIDATE);
  validate_shape(shape, input, limits);
  occ::handle<TDataStd_Name> name;
  if (root.FindAttribute(TDataStd_Name::GetID(), name))
    prepared.name = step_utf8(name->Get(), input);
  prepared.metadata.size = sizeof(prepared.metadata);
  prepared.metadata.version = normalizations ? 2 : 1;
  prepared.metadata.reserved = normalizations;
  prepared.metadata.name_bytes = static_cast<uint32_t>(prepared.name.size());
  prepared.metadata.unit_bytes = static_cast<uint32_t>(prepared.unit.size());
  prepared.metadata.declared_meters_per_unit = declared;
  prepared.metadata.resolved_meters_per_unit = 0.001;
  auto colors = XCAFDoc_DocumentTool::ColorTool(doc->Main());
  Quantity_ColorRGBA color;
  const bool found = colors->GetColor(root, XCAFDoc_ColorSurf, color) ||
                     colors->GetColor(root, XCAFDoc_ColorGen, color);
  if (found) {
    if (!std::isfinite(color.Alpha()) || color.Alpha() != 1)
      input.stop(OCC_READ_FORMAT, "STEP transparency unsupported");
    prepared.metadata.has_color = 1;
    prepared.metadata.rgba[0] = color.GetRGB().Red();
    prepared.metadata.rgba[1] = color.GetRGB().Green();
    prepared.metadata.rgba[2] = color.GetRGB().Blue();
    prepared.metadata.rgba[3] = 1;
    for (double value : prepared.metadata.rgba)
      if (!std::isfinite(value) || value < 0 || value > 1)
        input.stop(OCC_READ_FORMAT, "Invalid STEP general color");
  }
  input.check(0);
  return shape;
}
