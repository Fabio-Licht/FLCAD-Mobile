# G-109 — Category B Manual QA 01

Status: FAILED — NOT ELIGIBLE FOR FEATURE FREEZE  
Date: 2026-08-17  
Evidence source: operator's first manual Release Windows session, written
observations and `C:\TRABALHO\teste\TESTE DE USO 17-08-26.mp4` (53.97 s,
710x814, recorded 2026-08-17).

Video review status: REVIEWED IN FULL BY CODEX.

## Decision

Category B implementation remains accepted at architectural/code-review level,
but operational certification failed. Feature Freeze is not authorized.
Category C remains blocked.

The session could not reliably reach or evaluate the Category B surface tools
because foundational viewport, selection, sketch and performance behavior made
the workflow impractical.

## Operator observations

| Area | Observed behavior | Severity | Certification impact |
|---|---|---:|---|
| World axes/planes | Axes and planes render at excessive size and cross UI panels | Critical | Scene is visually unusable immediately after New Project |
| Axis identification | X/Y/Z letters are absent | High | Orientation is ambiguous |
| View triad | Fixed corner coordinate triad is absent | High | Camera orientation cannot be read reliably |
| Rendering | Visual quality is described as extremely poor | Critical | Surface/curve inspection cannot be performed |
| Click feedback | No visible indication of click location or accepted pick | Critical | Selection intent cannot be verified |
| Mesh visibility | Hide Mesh does not hide the mesh | Critical | Sections, sketches and surfaces cannot be isolated |
| Sketch placement | Sketch entities are created at uncontrolled locations | Critical | Sketch geometry is not trustworthy |
| Plane picking | Original world planes do not reliably accept clicks | Critical | Section/Sketch plane selection is blocked |
| Path access | A `PathAccessException` alarm appeared | Critical | Persistence/import/export state may be unsafe |
| Section workflow | A Section was created, but choosing its plane was very difficult | High | Section command is technically reachable but operationally poor |
| Zoom | Zoom causes geometry to disappear almost completely | Critical | Camera navigation is unstable |
| Best Fit Spline | Operator could not determine whether fitting occurred | High | Preview/result feedback is insufficient |
| Curve rendering | Lines are excessively thick | High | Curve shape and fitting quality cannot be inspected |
| Responsiveness | Almost every command appears to freeze during execution | Critical | Continuous professional use is impossible |
| Sketch control | Circles were created away from the intended click position | Critical | Local-coordinate/picking behavior failed |
| Sketch editing | Circle diameter and line extension could not be edited | Critical | Basic sketch editing is not operational through the UI |
| Workbench discoverability | Operator could not locate Extrude or creation of 3D Curves outside Sketch | High | Command organization and capability visibility are inadequate |

## Video evidence timeline

The video is a chronological review of the operator's captured Release session,
shown through a WhatsApp conversation. Elapsed timestamps below refer to the
53.97-second video, not the clock printed in each WhatsApp message.

| Video time | Visible evidence | Finding |
|---:|---|---|
| 00:00–00:10 | Imported mechanical mesh and Recognition panel | Selection intent/click location is not visibly represented; the operator asks where to click for plane recognition |
| 00:10–00:14 | Recognition hypothesis followed by red destructive/dependency preview | The visual state is dominated by full-object coloring and modal impact UI, making the selected geometric region difficult to understand |
| 00:14–00:18 | Explorer Mesh context menu and Hide attempt | Mesh Hide is reported as nonfunctional and blocking; Sketch Hide later works but is slow and appears to freeze |
| 00:18–00:22 | Mesh with yellow/green Sketch primitives at unrelated positions | Sketch entities are visibly detached from a controlled local plane and click feedback is absent |
| 00:21–00:24 | Error text in the Sketch workspace | Confirmed persistence failure: `PathAccessException: Cannot rename file ... cad-document-history.json.tmp` to `cad-document-history.json`; OS Error 32, file used by another process |
| 00:23–00:28 | Section displayed on the imported mesh | Section creation is visually present and is one of the few confirmed successful operations |
| 00:27–00:32 | Section/Sketch overlay | Sketch From Section is visibly projected onto a different Z-plane/location instead of remaining coincident with the Section |
| 00:30–00:35 | Highly magnified viewport | Zoom makes the model and panels difficult to read; contextual UI is effectively lost |
| 00:33–00:39 | Magenta fitted curve over cyan/yellow curves | A magenta result appears, but line thickness and overlapping layers prevent visual confirmation of Best Fit accuracy or commit state |
| 00:37–00:42 | Full application view after commands | Operator reports a white initial freeze in the upper tab area for almost every command |
| 00:40–00:47 | Recognition result on a narrow cylindrical-looking region | Region intended as cylinder is reported/visualized as Plane, indicating recognition/selection mismatch in this case |
| 00:44–00:51 | Large translucent sphere/plane/sketch overlays | Sketch and Fill results are spatially inconsistent, nearly transparent and visually indistinguishable from references/previews |
| 00:49–00:54 | Transform panel with separated objects | Mesh was moved 500 mm, but plane/Sketch/other entities could not be selected consistently afterward |

## Confirmed exception

The video makes the persistence alarm legible:

`PathAccessException: Cannot rename file to ...\\cad-document-history.json`,
with source `cad-document-history.json.tmp` and `OS Error: O arquivo já está
sendo usado por outro processo, errno = 32`.

This is a real filesystem atomic-replace/locking failure, not a generic UI
warning. Its root cause is not yet established: the evidence does not identify
whether the competing handle belongs to FLCAD, synchronization software,
antivirus or another process. No product correction is authorized by this QA
record alone.

## Positive evidence

The review also confirms that some backends are producing visible output:

- STL mesh is imported and rendered;
- a Recognition hypothesis is produced;
- a Section curve is produced and displayed;
- Sketch entities can be created;
- a magenta curve consistent with a spline/fitting result is displayed;
- transform can move the mesh numerically.

These outputs do not satisfy operational certification because selection,
coordinate systems, visual differentiation, latency and persistence remain
unreliable.

## Certification results

| Required Category B item | Result | Reason |
|---|---|---|
| Offset + Walls on Face | Not tested | Reliable Face/plane selection and usable viewport were unavailable |
| Offset + Walls on open Shell | Not tested | Same foundational blockers |
| Zebra | Not certified | Surface inspection workflow was not reliably reachable |
| Reflection | Not certified | Surface inspection workflow was not reliably reachable |
| Curvature | Not certified | Surface inspection workflow was not reliably reachable |
| Gaussian | Not certified | Surface inspection workflow was not reliably reachable |
| Draft | Not certified | Surface inspection workflow was not reliably reachable |
| Preview → Cancel → Apply | Not certified | Selection/feedback/performance prevented trustworthy execution |
| Undo → Redo | Not certified | No valid Category B operation was completed |
| Persistence | Not certified | `PathAccessException` was observed and no complete round trip was achieved |
| Full Release smoke | Failed | Workflow was not practically usable end to end |

## Technical investigation queue

No cause is asserted before evidence collection. The next diagnostic pass must
identify exact file, class, method and reproducible condition for:

1. camera-dependent visual sizing and clipping of WCS axes/planes;
2. missing axis labels and missing fixed viewport triad;
3. render quality, line widths and analysis readability;
4. pick feedback and world-plane hit testing;
5. Mesh visibility projection/update;
6. Sketch local-plane coordinate conversion and click capture;
7. zoom camera bounds, near/far planes and disappearing geometry;
8. Best Fit Preview/Apply/result differentiation;
9. command latency by controller/kernel/projection/render stage;
10. the complete `PathAccessException` stack trace and target path;
11. Inspector editing paths for circle diameter and line extension;
12. toolbar/workbench discoverability for 3D Curves and commands that actually
    belong to the current product scope.

## Gate

Do not declare Feature Freeze. Do not start Category C. Before another Category
B certification attempt, the blocking defects must be triaged and explicitly
authorized for correction. Architecture must not be changed merely because UX
and integration are failing.
