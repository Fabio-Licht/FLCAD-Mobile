# G-109 — Design Review Addendum 02

Status: APPROVED — DESIGN FREEZE  
Date: 2026-08-17  
Scope: Category B functional expansion only

## 1. Authority and boundaries

This addendum complements, without replacing:

- `G109_OCCT_AUDIT.md`;
- `G109_CATEGORY_B_OCCT_AUDIT.md`;
- `G109_CATEGORY_B_DESIGN_REVIEW.md`;
- `G109_OFFICIAL_WORKBENCH_GAP_AUDIT.md`.

It does not change `CadRuntime`, `CadDocument`, Geometry Input Resolver,
`ShapeHandle`, transient materialization, persistence, scene projection or the
viewport architecture. Category A remains frozen. Category C (`Fair`, `Morph`)
remains blocked.

All commands in this document use the existing lifecycle:

`Select inputs → Preview → inspect result/impact → Apply or Cancel`.

Preview is transient. Apply is the only action allowed to create the definitive
kernel result and document revision. Cancel destroys transient kernel/display
state and restores the previous selection and visualization.

## 2. Offset Intelligence

### 2.1 Shared selection flow

1. Start `Surface > Edit > Offset`.
2. Select a compatible Surface, Face, Shell or Body.
3. Select one mode: `Offset`, `Replace`, `Offset + Walls` or
   `Offset + Close`.
4. Select direction: `Inside`, `Outside` or `Bilateral`.
5. Enter distance. Bilateral mode exposes independent inside/outside distances
   with an optional linked-values toggle.
6. For wall modes, inspect every source Boundary and explicitly choose
   `Wall` or `Open`.
7. Generate and inspect Preview.
8. Apply or Cancel.

No Boundary receives a wall implicitly. A default recommendation may be shown,
but every wall/open state remains visible and editable before Apply.

### 2.2 Modes and definitive outputs

| Mode | Original | Result | Apply behavior |
|---|---|---|---|
| Offset | preserved | new Surface/Face per selected direction | inserts a new document entity |
| Replace | revised | offset Surface/Face | replaces geometry through the existing revision/history path |
| Offset + Walls | preserved | offset plus walls; usually open Shell | inserts result with its real topological type |
| Offset + Close | preserved | offset, selected walls and closing topology | inserts a closed Shell when validation confirms closure; never promotes an open Shell |

Bilateral Offset creates two explicit results or one compound result according
to the existing document operation contract. The Preview and Inspector must
state which representation will be committed. Replace + Bilateral is invalid
unless the operator explicitly selects which side replaces the source; Apply
remains disabled until that choice is made.

### 2.3 Boundary wall selection

The task panel lists stable Boundary IDs, length, type and current choice.
Selecting a row highlights that Boundary in the viewport. Viewport selection
updates the same row. Commands `All Walls`, `All Open` and `Invert` are editing
shortcuts only; their resulting per-Boundary choices remain explicit.

### 2.4 Preview

- source: cyan;
- outside offset: translucent orange;
- inside offset: translucent violet;
- walls: darker orange;
- open boundaries: red dashed highlight;
- closing faces: translucent green;
- failed/self-intersecting regions: red.

The Preview reports source/offset/wall/closing components separately, free
edges, shell count, closure, self-intersections and actual output type.

### 2.5 Apply and Cancel

Apply is enabled only when every Boundary has a declared state and the result
passes the validity required by its advertised type. `Offset + Close` requires
a valid closed Shell. Cancel removes all transient offset, wall and closure
handles without changing the source entity.

### 2.6 Inspector and Assistant

Inspector: mode, signed distances, direction, source Face/Surface/Shell,
Boundary states, walls created/failed, open edges, sewing tolerance, output
topology and diagnostic.

Assistant recommendations:

- reduce distance when local radius or self-intersection blocks the result;
- identify open Boundaries and suggest wall/close choices;
- recommend Working Copy before Replace;
- state whether the result is Surface, open Shell or closed Shell.

## 3. Boundary Intelligence

### 3.1 Boundary Extend deterministic retention policy

The result must never depend on OCCT exploration order or “first Face”. The
following policy is mandatory and ordered:

1. **Stable input frame:** resolve source Face, selected Boundary, source
   orientation, target and operator-selected extension side before execution.
2. **Anchor samples:** create fixed samples on the unmodified interior of the
   source Face. Samples are derived from normalized UV positions away from the
   selected Boundary and are projected to the source Face within tolerance.
3. **Candidate generation:** extend and split using the approved OCCT
   composition. Enumerate every resulting Face.
4. **Source-domain preservation:** discard candidates that do not contain the
   greatest number of valid interior anchor samples.
5. **Boundary adjacency:** among remaining candidates, retain those containing
   the original non-extended boundaries, using OCCT topology history where
   available and tolerance-aware geometric identity otherwise.
6. **Selected-side test:** require the added region centroid to lie on the
   operator-selected side of the source Boundary in the local surface frame.
7. **Target test:** for `Up To`, require the new limiting Boundary to lie on or
   intersect the selected target within tolerance.
8. **Deterministic score:** rank by anchor count, preserved-boundary count,
   target residual, then absolute area change. The lexicographically smallest
   stable topology signature is used only as a final exact tie-breaker.
9. **Ambiguity:** if the best two candidates remain equal within configured
   geometric tolerances before the topology-signature tie-break, Preview is
   marked ambiguous and Apply is disabled. The operator must select the desired
   candidate explicitly in the viewport.

The report records candidate count, chosen candidate signature, anchor score,
preserved boundaries, side classification, target residual and ambiguity.

### 3.2 Boundary Extend workflow

`Face/Surface → Boundary → By Length or Up To → side → target/length →
continuity → Preview → Apply/Cancel`.

Targets accepted by `Up To`: Plane, Curve/Edge/Wire/Boundary and
Surface/Face. The resolver may materialize compatible inputs transiently.

Preview uses cyan source, magenta active Boundary, green target and translucent
orange extension. Candidate alternatives appear numbered only when ambiguity
requires an explicit operator decision.

### 3.3 Boundary Trim Keep Point policy

Fragment selection by enumeration index is forbidden. The mandatory flow is:

`Face/Surface → Boundary → cutting geometry → Keep Point → Preview →
Apply/Cancel`.

Keep Point rules:

1. The point is captured from the viewport on the pre-trim source Face using
   the existing picking pipeline.
2. The point is stored in source Face parameter space when available, together
   with its 3D position and tolerance.
3. After splitting, each candidate Face is tested by projecting the Keep Point
   onto its support surface and classifying it against its trimmed domain using
   the official BRep face classifier.
4. The unique candidate classified `IN` is retained. `ON` is accepted only
   when exactly one candidate satisfies the tolerance.
5. If no candidate is `IN`, select the unique candidate whose trimmed-domain
   distance is within tolerance. Otherwise Preview is invalid.
6. Multiple equally valid candidates are ambiguous; Apply is disabled until a
   new Keep Point is chosen.

The Keep Point remains visible as a yellow marker. The retained region is
orange translucent; discarded regions are red translucent. The report records
the point, classification, fragment count, retained Face signature, affected
wires, gaps and tolerances.

## 4. Topology Workbench

Toolbar location: `Surface > Topology`. All tools reuse official topology
entities and ShapeHandles; none creates a parallel topology graph.

### 4.1 Unsew Face

Flow: `Select one Face in a Shell → Preview separation → Apply/Cancel`.

Preview shows the selected Face in orange and the remaining Shell in cyan,
with newly open edges in red. Apply creates the official separated Face and the
remaining Shell/revision, preserving source relationships and reporting open
edges. Cancel restores the original Shell display.

### 4.2 Unsew Selected

Flow: `Select two or more Faces → Preview groups → Apply/Cancel`.

Connected selected Faces remain grouped when their shared topology is retained;
connections to unselected Faces are removed. Preview colors each resulting
component distinctly and marks every created open Boundary.

### 4.3 Unsew All

Flow: `Select Shell/Body → confirm affected Face count → Preview exploded
topology → Apply/Cancel`.

Apply materializes independent official Faces and retires/revises the source
Shell according to the existing document history policy. It never deletes the
source silently.

### 4.4 Replace Face

Flow: `Select owning Shell/Body → select Face to replace → select replacement
Face/Surface → map boundaries → Preview → Apply/Cancel`.

Preview shows old Face red, replacement orange and boundary correspondence
vectors. Apply requires valid orientation, boundary correspondence within
tolerance and a valid rebuilt/sewn result. Working Copy is recommended whenever
dependent topology will change.

### 4.5 Delete Face

Flow: `Select Face(s) → dependency impact → Preview open result →
Apply/Cancel`.

Preview highlights removed Faces red and newly open boundaries magenta. Apply
uses the existing safe-delete/history policy and persists the actual resulting
Face set or open Shell. Delete never heals or fills the opening implicitly.

### 4.6 Heal Local

Flow: `Select Face/Wire/Edge/Boundary → choose approved local repair actions →
Preview proposals → Apply/Cancel`.

Only selected topology and directly required adjacent topology may change.
Preview distinguishes proposed modifications and reports before/after gaps,
tolerances, orientation and validity. Apply is blocked when the proposed local
repair would require undeclared global changes.

### 4.7 Topology command reports

Every command reports input/output Face, Edge, Wire, Shell and Body counts;
open edges; gaps; maximum tolerance; affected IDs; ShapeHandle; validity; and
status `OK`, `Attention` or `Critical`.

Assistant messages are specific:

- Unsew: explain resulting open boundaries and dependent entities;
- Replace Face: recommend Working Copy and verify boundary mismatch;
- Delete Face: enumerate dependents and resulting shell state;
- Heal Local: compare requested tolerance with geometry scale;
- Sew: recommend Validate when free edges remain.

## 5. Surface Analysis

Toolbar location: `Surface > Analysis`. Modes are mutually exclusive display
modes unless a documented combination is supported. Closing the mode restores
the previous material exactly.

### 5.1 Common flow

`Select Surface/Face/Shell → select analysis mode → configure legend/range →
live viewport analysis → Close`.

Analysis is non-destructive. `Apply` stores only operator-approved analysis
settings/bookmark when the existing document contract supports it; it never
changes geometry. `Cancel`/Close removes the transient visualization.

### 5.2 Modes

| Mode | Viewport behavior | Required legend/data |
|---|---|---|
| Zebra | continuous moving/rotatable stripes evaluated from surface normals | stripe direction, width, phase, discontinuity emphasis |
| Reflection | environment/reflection bands driven by normals | environment orientation, contrast, continuity breaks |
| Curvature | signed selected principal/mean curvature color map | units, min/max, zero and clamped ranges |
| Gaussian | Gaussian curvature color map | negative/zero/positive diverging scale and numeric range |
| Draft | face coloring from normal versus pull direction | pull direction, draft angle threshold, positive/negative/undercut colors |

The existing OCCT differential-property inspection is the authoritative source
for geometry values. Visualization must use the existing viewport/rendering
pipeline and existing display meshes; no second renderer or Scene Graph is
permitted.

### 5.3 Update and performance

Camera movement updates view-dependent Zebra/Reflection uniforms only. It must
not retessellate geometry. Curvature/Gaussian/Draft scalar fields are cached by
ShapeHandle revision, tessellation revision and analysis parameters. Selection
or legend changes update only affected display entities.

Invalid/undefined differential samples use a distinct neutral/error color and
are counted in the report; they must not be silently converted to zero.

## 6. Topology Inspector

The existing Property Inspector receives a `Topology` section; no parallel
inspector is created. It presents:

- Faces, Edges, Wires, Shells and Bodies counts;
- selected/active topology IDs;
- open and non-manifold edges;
- measured gaps: maximum, mean and count above tolerance;
- minimum/maximum/working tolerances;
- shell closure and BRep validity;
- operation result and affected entities.

Clicking a count expands the official document entities. Hovering or selecting
an item synchronizes Explorer and viewport highlight.

## 7. Property Inspector expansion

During Category B operations, the Inspector must additionally show:

- active Face and Boundary;
- Offset mode and inside/outside/bilateral distances;
- per-Boundary wall/open state;
- Heal scope and proposed fixes;
- Sew tolerance, free edges and result closure;
- Shell input/output type and ShapeHandle;
- Preview validity and document impact.

Only kernel/document facts may be presented as final values. Estimates are
explicitly labeled as Preview.

## 8. Engineering Assistant expansion

The Assistant remains consultive and never triggers Apply. It may recommend:

- `Offset + Walls`: change distance, wall selection or closure based on free
  edges and local-radius diagnostics;
- `Heal Local`: choose the narrowest repair scope and validate afterward;
- `Replace Face`: create Working Copy and inspect boundary mismatch;
- `Delete Face`: review dependencies and resulting open Shell;
- `Sew`: adjust tolerance only within documented geometry limits and run
  Validate after sewing.

Messages are categorized as Suggestion, Attention or Completed and link to the
same facts displayed by the Inspector.

## 9. UX contract

- Toolbar groups: `Surface > Edit`, `Surface > Topology`,
  `Surface > Analysis`.
- Every destructive/geometric command has explicit Preview, Apply and Cancel.
- `Enter` applies only a valid preview; `Esc` cancels.
- Icons follow the existing application icon family and do not introduce a
  second visual system.
- Tooltips state selection order and accepted input types.
- Invalid selections provide a specific reason and preserve the active command.
- Viewport, Explorer and Inspector selection remain synchronized.
- No command applies on double-click or selection completion alone.

## 10. Release smoke specification

After implementation and Feature Freeze, execute exclusively through the
Windows Release UI:

1. Offset as new Surface; Replace; Undo/Redo.
2. Offset + Walls with mixed Wall/Open Boundary choices.
3. Offset + Close producing a validated closed Shell.
4. Inside, Outside and Bilateral previews and Apply.
5. Boundary Extend by length and up to Plane/Curve/Surface; verify deterministic
   retained region and ambiguity handling.
6. Boundary Trim by Curve/Plane/Surface using Keep Point; verify ambiguous and
   boundary-point rejection.
7. Unsew Face, Selected and All; inspect open edges.
8. Replace Face and Delete Face with impact Preview.
9. Heal Local and Validate before/after.
10. Sew and inspect closure/tolerances.
11. Zebra, Reflection, Curvature, Gaussian and Draft live visualization.
12. Save, close and reopen; verify committed geometry/topology and absence of
    transient previews.

For every geometric command validate Preview, Cancel without residue, Apply,
Undo, Redo, Inspector, Assistant, Explorer, viewport and persistence.

## 11. Design Freeze gate

After explicit approval of this addendum:

- its selection order, modes, Preview, Apply, Cancel, Inspector and Assistant
  behavior become frozen;
- no additional G-109 functionality may be introduced;
- implementation may cover only the approved Category B gaps;
- changes require a demonstrated bug or explicit operator request;
- Category C remains blocked.

The mandatory lifecycle after approval is:

`Implementation → Feature Freeze → Windows Release Smoke → QA → Operator
Review → Approval`.
