# CATIA Camera Behavior Specification

Status: behavioral reference for G-109R Camera Recovery.  This document defines
observable operator behavior only.  It does not prescribe classes, state fields,
matrices, algorithms or implementation architecture.

## Scope and reference profile

The primary reference is classic CATIA V5 Examine-mode navigation with a
three-button mouse.  Where modern 3DEXPERIENCE documentation describes a
different `CATIA Profile`, that difference is identified explicitly.

An exact claim about CATIA must have one of these evidence levels:

- **Documented** — stated by CATIA/Dassault user assistance.
- **Behavioral inference** — consequence visible to an operator, but not stated
  as an internal camera rule by the documentation.
- **Operator verification required** — must be recorded on the operator's CATIA
  installation before becoming normative.

## 1. Rotation center

### Documented CATIA behavior

- The camera `Target` is the center of rotation and is located at the center of
  the viewport.
- Clicking the middle mouse button at a desired point sets the center of
  rotation; its coordinates are memorized with a saved camera/view.
- A middle click centers the display at the indicated location.
- During Rotate, CATIA displays a rotation-sphere symbol around the object.

### When the center changes

The following changes are documented:

1. Middle-click at a location: explicitly sets and centers that location.
2. Loading a saved named view/camera: restores its memorized Target.
3. Fit All In: reframes all document contents; the resulting center must be
   treated as the new view center.

No reviewed CATIA V5 documentation states that ordinary left-click selection of
a face, surface, edge, curve or sketch changes the camera Target.

**Normative behavior:** selection alone must not visibly jump, recenter or change
the next Orbit.  If the operator wants a different rotation center, middle-click
is the documented CATIA V5 action.

## 2. Pan

### Documented CATIA behavior

- Middle-button drag pans.
- Pan moves the document contents by translating the camera viewpoint.
- Pan is a translation, never a rotation.

The public documentation reviewed does not explicitly state the world-coordinate
update rule for the camera Target during Pan.

### Required observable behavior

- Camera orientation is unchanged for the entire gesture.
- Geometry follows the pointer like a sheet of paper.
- Releasing Pan and immediately starting Orbit produces no jump or mode reset.
- The rotation sphere/center remains coherent with the translated view.

Whether CATIA stores that continuity by translating Target or by an equivalent
viewpoint representation is an implementation detail and is outside this spec.

## 3. Orbit / Rotate

### Documented CATIA behavior

- Hold the middle button, then hold the left or right button, then drag.
- A rotation-sphere symbol appears around the object.
- Rotation uses the current camera Target/rotation center.
- Releasing the buttons ends rotation without changing the chosen center.

### Required observable behavior

- Rotation begins from the exact view left by the preceding Pan or Zoom.
- The model does not jump when the second button is pressed.
- The rotation center does not migrate during the drag.
- Horizontal and vertical motion remain continuous through a long gesture.
- Starting another Orbit without a new middle-click reuses the same center.

## 4. Zoom

### Classic CATIA V5

- Zoom In and Zoom Out commands apply predetermined increments.
- `Zoom In Out` supports progressive zoom by dragging.
- The classic three-button gesture starts from middle-button mode, uses a
  left/right click transition, and continues by dragging with the middle button.
- The reviewed V5 help explicitly says rolling an IntelliMouse wheel is not
  supported as the middle-button navigation gesture.

### Modern 3DEXPERIENCE CATIA Profile

- Mouse-wheel forward zooms toward the mouse pointer.
- Mouse-wheel backward zooms out.

These are different published profiles.  Therefore “exact CATIA V5” and
“CATIA-profile mouse wheel” must not be treated as the same requirement.

### Required observable behavior

- Zoom never changes the established rotation center silently.
- One continuous zoom gesture has one continuous response; it does not repick or
  switch focus between faces during the gesture.
- Zoom-in followed by the equivalent zoom-out returns to the same perceived
  scale and framing.
- Device event frequency must not change the effective zoom speed.

For FLCAD, mouse-wheel behavior is a compatibility extension unless the operator
confirms that the CATIA V5 installation used as the acceptance reference has
wheel zoom enabled by its driver or configuration.

## 5. Fit All In

### Documented CATIA behavior

`Fit All In` zooms the current view so that all current document contents fit in
the available geometry area.

### Required observable behavior

- All visible model content fits with a stable margin.
- Current orientation is preserved unless the reference CATIA session proves
  otherwise.
- The resulting viewport center becomes the coherent center for the next Pan,
  Orbit and Zoom sequence.
- WCS decorations and screen overlays do not enlarge the fitted model bounds.

## 6. Selection and focus changes

CATIA documents preselection, selection highlighting and navigation as separate
behaviors.  No reviewed official material says that selecting another geometric
region automatically changes the camera Target.

Therefore the accepted CATIA V5 baseline is:

- hovering changes prehighlight only;
- left-click changes selection only;
- neither action moves the view;
- middle-click changes the view/rotation center;
- subsequent Pan, Orbit and Zoom remain continuous from that viewpoint.

Automatic orbit-focus transfer on ordinary selection is a non-CATIA behavior and
must not be enabled in the CATIA V5 profile without direct operator evidence.

## 7. Continuous navigation sequence

The normative sequence is:

```text
Fit All In
  -> optional middle-click to center the working region
  -> Pan
  -> Orbit
  -> Zoom
  -> Select
  -> Pan / Orbit / Zoom
```

Continuity requirements:

- no gesture silently chooses a new rotation center;
- switching between Pan, Orbit and Zoom produces no visual discontinuity;
- selection never causes a camera jump;
- the active center persists until middle-click, Fit All In or loading another
  saved viewpoint changes it;
- the operator is never required to repair drift produced by a previous gesture.

## 8. Comparative audit: current FLCAD candidate

| Behavior | CATIA V5 reference | Current FLCAD candidate | Result |
|---|---|---|---|
| Set center | Middle-click centers display and memorizes Target | Middle-click changes an internal rotation point without centering the display | Mismatch |
| Selection | Highlight/selection; no documented camera recenter | Selection transfers the next Orbit to the picked region | Mismatch |
| Pan | Viewpoint translation; no rotation | Translation is available, but its continuity has repeatedly failed operator QA | Not approved |
| Orbit | Current Target; sphere feedback; stable across gestures | Uses a separate automatically changing working-region point | Mismatch |
| Classic Zoom | Chord/progressive or fixed command increments | Wheel-based picked anchor | Mismatch |
| Wheel Zoom | Not classic V5; available in modern CATIA Profile | Wheel session with picked anchor | Profile must be decided |
| Fit | Fits all document contents | Fits visible scene geometry | Candidate; operator verification required |

## 9. Mandatory CATIA capture before controller rewrite

The following test must be recorded on the operator's actual CATIA V5 setup:

1. Open a representative reverse-engineering part.
2. Fit All In and capture the view.
3. Middle-click a recognizable off-center feature and capture the result.
4. Orbit and record where the rotation sphere appears.
5. Pan, then Orbit without another middle-click.
6. Zoom in and out using the operator's normal CATIA gesture.
7. Select a different face without middle-clicking, then Orbit.
8. Record whether the center changes after selection.
9. Record whether rolling the wheel is active and which direction it anchors.

Required evidence:

- CATIA release and service pack;
- mouse/driver model and CATIA navigation settings;
- video with visible cursor and buttons;
- before/after frames for every step;
- operator description of sensitivity and acceleration.

The controller rewrite must not begin until items 5, 7 and 9 are empirically
resolved, because public documentation does not fully specify their internal
viewpoint transitions and published CATIA profiles differ on wheel behavior.

## Sources

- CATIA V5 Infrastructure User Guide: *Activating Viewing Tools*.
- CATIA V5 Infrastructure User Guide: *Creating, Modifying and Deleting
  User-defined Views*.
- CATIA V5 Infrastructure User Guide: *Panning*.
- CATIA V5 Infrastructure User Guide: *Rotating*.
- CATIA V5 Infrastructure User Guide: *Zooming In* and *Zooming Out*.
- CATIA V5 Infrastructure User Guide: *Fitting All Geometry in the Geometry
  Area*.
- Dassault Systèmes 3DEXPERIENCE User Assistance: *Mouse Controls*, CATIA
  Profile.

