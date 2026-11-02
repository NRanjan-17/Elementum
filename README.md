# Elementum

Elementum is a periodic table app for iPhone and iPad. It lets you explore all 118 elements, meet a new one every day, and combine elements and compounds to see how they react, with the reaction predicted by an AI model that runs entirely on the device.

## Features

- **Periodic table** with all 118 elements, plus the s, p, d and f blocks on their own, each in its own colour.
- **Element details**: atomic number and mass, electron configuration, block, bonding type, phase, appearance, who discovered it, and a short description.
- **Element of the Day** on the Home screen, a new element every day.
- **Combine**: pick elements and compounds, set quantities, and get a balanced equation and a one-line explanation. If substances don't react, it says why. You can also build and save your own compounds.
- **Finder**: search by name, symbol or atomic number.
- **iPad layout** with a sidebar, so you can browse and read side by side.

## On-device AI

Combine uses [Sapient](https://github.com/openhorizon-labs/sapient-swift) to run Qwen2.5-1.5B-Instruct on the device. Nothing is sent to a server.

- The model is downloaded once from the Combine tab, then works offline. Devices with more than 6 GB of RAM get the full model; others get the 4-bit build (about 1 GB).
- Weights are stored in the app's Caches folder, so iOS can reclaim them and deleting the app removes them.
- While downloading, the screen stays on. On iOS 26 the download continues in the background as a continued-processing task; on earlier versions it pauses when background time runs out and resumes from the partial files when you return. A stalled download restarts itself.
- `Elementum.entitlements` requests the increased memory limit and extended virtual addressing so the model loads reliably.

The relevant code is in `Elementum/Data/ModelManager.swift` (download) and `Elementum/Components/ReactionModel.swift` (loading the model and predicting reactions).

## Requirements

- iOS or iPadOS 18.2 or later
- Xcode 26 or later
- Swift Package Manager fetches `sapient-swift`, which downloads Sapient's prebuilt `SapientFFI.xcframework`

## Getting started

```sh
git clone https://github.com/NRanjan-17/Elementum.git
cd Elementum
open Elementum.xcodeproj
```

Choose the **Elementum** scheme and run it on a simulator or device. The first build takes a while because Xcode downloads the Sapient binary (about 200 MB).

To try Combine, open the Combine tab and download the model. The simulator works, but reactions run much faster on a real device.

## Project structure

```
Elementum/
  ElementumApp.swift      App entry and splash
  Views/                  Tab layout, Home, Combine, Finder, model download, splash
    Groups/               Periodic table and the s, p, d, f block screens
  Components/             Element and compound cells, pickers, the logo, the reaction model
  Data/                   Element data, SwiftData compounds, formula formatting, model download
  Resources/              Elements.json, the asset catalog, and the app icon (Elementum.icon)
AppStore/                 App Store screenshots, header, icon sources and listing text
  tools/                  Scripts that generate them (see below)
```

## App icon and App Store assets

The app icon is an Icon Composer file, `Elementum/Resources/Elementum.icon`, built from three SVG layers so the "El" symbol gets Liquid Glass. It is generated, along with the screenshots and header in `AppStore/`, by the scripts in `AppStore/tools/`:

```sh
cd AppStore/tools
python3 icon.py       # icon layers and Elementum.icon
python3 previews.py   # App Store screenshots and header images
```

The scripts need Pillow and fontTools (`pip install pillow fonttools`) and Google Chrome, which renders the SVGs to PNG.

The App Store listing text (subtitle, promotional text, description, what's new, keywords) is in `AppStore/app-store-connect.txt`.

## Author

Made by [Nalinish Ranjan](https://github.com/NRanjan-17).
