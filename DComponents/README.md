# DComponents

Delphi components and libraries used by the Delphi projects of this repository.

## My own

Licensed as the rest of the repository.

- `Libs` - utility units, among them `Views` (bitmap processing), `XMLObjects`, `XMLParsers`, `XMLWriters`, `ScaleForms`, `LManagers`, `Map64`, `SubStreams`, `TextWindowProps`. It also holds a copy of `RegExpr.pas`, see `RegExpr` below.
- `NicePanel`, `NiceScrollBox`, `NiceSplitter` - small descendants of the standard VCL controls.

## Third-party

Each of these stays under its own license, stated in its files.

- `DUnit` - DUnit testing framework by the DUnit Group. Mozilla Public License 1.1; `Contrib/DUnitWizard` is under the GNU Lesser General Public License.
- `GraphicEx` - GraphicEx image library 9.9 by Mike Lischke. Mozilla Public License 1.1. The `.OBJ` files are the compiled JPEG library: this software is based in part on the work of the Independent JPEG Group.
- `RegExpr` - TRegExpr regular expressions library by Andrey V. Sorokin. The license is in the header of `RegExpr.pas`.
- `TNT` - Tnt Delphi Unicode Controls 2.0.23 by Troy Wolbrink. The terms are in `Readme.txt`.
- `VT3.8.3` - Virtual Treeview 3.8.3 by Mike Lischke. Mozilla Public License 1.1 or GNU Lesser General Public License 2.1.
- `VT4` - Virtual Treeview 4.0.17 by Mike Lischke, under the same license. This copy is modified: its units and classes carry a `4` suffix in their names.
