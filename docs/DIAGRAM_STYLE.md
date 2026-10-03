# Diagram style guide

Every study figure is drawn in code by `tools/diagrams/figs/*.py` on the
shared canvas in `tools/diagrams/nec_style.py`. This page is the quality bar
for adding or changing one. The procedure, the mask system and the audit
history are in `DIAGRAMS_AUDIT.md`.

## The bar

A journeyman should look at the figure and recognize the equipment straight
away, with nothing on it that's wrong, that leaks the answer, or that's
there just for decoration.

- **Real equipment, not gray boxes.** Draw a receptacle, panelboard,
  breaker, disconnect, meter, transformer, motor, box or raceway with the
  shared helpers below. A plain rectangle is fine only for things that
  really are plain boxes: a building, a room, a cabinet, an information card.
- **Believable proportions.** A duplex is about 0.64 as wide as it is tall,
  a breaker is taller than it is wide, a panelboard is about 1.6 times as
  tall as it is wide, and the disconnect handle is on the right side. Keep
  dimensioned things to scale where the figure says so ("not to scale"
  otherwise).
- **Technically right.** On a 5-15R face with the ground hole down, the
  taller neutral slot is on the left. A GFCI receptacle has TEST and RESET
  buttons between its faces. EGCs and bonding conductors are green, and
  bonding jumpers are amber. Check every depiction against the NEC 2023
  section it cites.
- **Readable at phone width.** The app shows a figure about 390-480 px
  wide on a phone and about 560 px in the desktop answer panel, with a
  fullscreen zoom. Values are 28-32 canvas units, object labels 22-24, and
  nothing is under 20 (`T_MIN`). No label may overlap another, run off the
  canvas or sit on top of a line.
- **No clutter.** Every mark answers a question, sets up the question or
  locates something. Leave out random texture, decorative icons and
  repeated legends.
- **Original artwork only.** Never trace or copy UpCodes, NFPA or
  manufacturer drawings, and never paste code text into figures beyond the
  short section references in the tag chip.

## Canvas, palette, type

- 800 units wide, rendered at 1.5x to PNG. Dark slate canvas (`BG`).
- Use the palette constants only (they mirror `src/ui/app_theme.gd`):
  `PANEL`/`PANEL_2` bodies, `EDGE`/`LINE` structure, `TEXT` labels, `MUTED`
  notes, `DIM` (cyan) dimensions, `ZONE` zones, `OK` answers and
  "permitted", `NO` "not permitted" and hazards, `AMBER` bonding jumpers and
  attention marks, `ORANGE` isolated-ground marks, `WIRE_*` conductors,
  `SOIL`/`CONCRETE`/`WATER`/`WOOD`/`STEEL`/`ROD`/`CLAMP` materials.
- Strokes: `SW_STRUCT` 4 for walls, floors and grade; `SW_OBJ` 3 for
  equipment outlines; `SW_THIN` 2 for detail, leaders and extension lines;
  `SW_DIM` 3 for dimension lines; `SW_WIRE` 4 for conductors.
- Text: Helvetica, ASCII only (MuPDF drops other glyphs). Dashes are drawn
  as segments (`dline`), never with `stroke-dasharray`.
- Title: `f.title(...)` at the top, muted bold. Section chip: `f.tag(...)`
  in a bottom corner, "NEC 210.52(C)".

## Dimensions, callouts, legends

- Dimensions: `ext()` dashed extension lines from the object, then `dim_h`
  or `dim_v` with arrowheads at both ends. The value goes beside the middle,
  in `DIM`, or through `value()` when it's an answer.
- Callouts: the label sits off the object with a `leader()` (thin line,
  dot on the object). Don't cross leaders, and don't point one through
  another label.
- Legends: `legend()` swatches, with the same symbol the figure uses.
- Information cards: `card()`, a rounded `PANEL` with a bold title.

## Shared equipment helpers (`nec_style.Fig`)

| Helper | Draws |
|---|---|
| `receptacle(x, y, s, gfci=, tr=, ig=, blank_center=)` | duplex 5-15R on its strap: two faces with neutral, hot and ground openings; GFCI TEST/RESET; IG orange triangle; TR mark |
| `nema_face(cx, cy, r, cfg)` | one receptacle face, `5-15`, `5-20` (T neutral), `6-15`, `6-20` |
| `plan_receptacle(x, y, r, gfci=)` | plan symbol, circle with two lines through it |
| `plug(x, y, w, h, facing, cord)` | grounding-type attachment plug, side view, with cord |
| `panel(x, y, w, h, breakers=, main=)` | panelboard: tub, dead front, trim screws, two columns of breakers on the bus cover, optional main; `breakers=0` leaves the dead front empty |
| `breaker(x, y, w, h, poles=, on=, rating=)` | molded-case breaker with lugs, handle slot, toggle up (ON) or down (OFF), handle tie for multipole |
| `mini_breaker(x, y, w, h, handle_left=)` | one plug-on breaker as it sits in a panel row |
| `disconnect(x, y, w, h, on=)` | enclosed safety switch: door seam, hasp, side operating handle |
| `meter(cx, cy, r)` | watthour meter in its socket: sealing ring, glass, register, dial |
| `transformer(x, y, w, h, kind="pad"/"pole")` | pad-mounted cabinet on its pad, or pole can with bushings and hanger |
| `coils(x, y, r)` | one-line transformer symbol |
| `motor(cx, cy, w, h)` | TEFC motor, side view: ribbed frame, end bells, shaft, feet, conduit box |
| `motor_symbol(cx, cy, r)` | one-line circled M |
| `box(x, y, s)` | outlet or junction box with a blank cover and two screws |
| `conduit(x1, y1, x2, y2, width, couplings=)` | pipe with edges, highlight and coupling bands |
| `rod(x, y, length)` | driven rod with its acorn clamp |
| `card(x, y, w, h, title)` | information card |

Pictorial views (elevations, sections, plans) use the pictorial helpers.
One-line and schematic views use the symbols (`coils`, `motor_symbol`,
switch and contact symbols). Don't mix the two kinds in one drawing.

## Answer safety

Before a question is answered, its figure shows only neutral context and
"?" badges. The build enforces this for every pre-answer record
(`build.strict_masks`, rule in `leakscan.strict_keys`/`strict_hits`): it
masks any label that

- states a rule value (length, percent, volts, amperes, VA, watts, degrees,
  hertz, ohms, AWG) the record's own stem doesn't give, or
- contains any answer choice, right or wrong, of *any* question served by
  the same figure. A visible distractor lets you rule it out, or
- names a section, table or Part ("250.53(A)(3)", "Table 310.16",
  "Part II"): that says where the answer is. An Article number alone
  ("Article 680") may show, like the breadcrumb. The section chip from
  `f.tag(...)` masks itself and reads "NEC ?" until answered.

Lengths compare in inches with 3% slack, so 6 ft 7 in, 6'7", 79 in, 2.0 m
and 2 m all match. Rating pairs ("120/240 V") count as two values. A
multi-row note is masked whole, before its rows, so it gets one badge.
A figure whose labels are the question's own data (the required exam
figures, or a setup label like "480 V") lists them in
`@figure(keep=[regex])`; a kept label still may not name a section. `value()`/`mask()` still mark the answer
regions by hand and ring them after answering. The strict masks only hide
text and reveal it after answering. `tools/tests/test_diagram_figures.py`
rechecks the committed labels and masks against every record's choices.

The scan reads text only, so check the pictures by hand. If the question
asks "which device", drawing that device plainly is a leak: draw it
generically and mask it, or show the figure only after answering
(`when: "after"`).

## Review procedure

1. `python tools/diagrams/build.py --scratch DIR --modules NAME` renders a
   module and its before/after-answer previews without touching shipped
   files.
2. Look at each figure at desktop width (560 px), at phone width (390 px)
   and at full size (zoom): recognizable equipment, readable labels, no
   overlap or clipping, consistent strokes and colors, the right NEC
   depiction, and masks covering every answer.
3. `python tools/diagrams/build.py` writes the shipped PNGs and masks;
   `--check` must report 0 problems. Then run `tools/tests/test_diagrams.gd`
   and the full `tools/verify.sh`.
