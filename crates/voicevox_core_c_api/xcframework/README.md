# xcframeworkフォルダの内容について
## Frameworks

iOS向けの配布ライブラリにXCFramework形式を採用しています。
このXCFrameworkは、端末用（arm64）と
シミュレータ用（arm64_x86_64-simulator）の2種類のFrameworkを
含みます。
それら2種類のFrameworkを作るための雛形として利用されます。

なお、この2つのframeworkはXcodeで空のframeworkを作成するとできます。
