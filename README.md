# Tama

Tama — нативная утилита для macOS с живым котом Sterling на рабочем столе. Питомец ненавязчиво отображает состояние Mac через поведение, а точные системные показатели будут доступны в строке состояния. Канонические требования находятся в `docs/PRODUCT_SPEC.md`.

## Требования

- Apple Silicon Mac;
- macOS 15 или новее;
- полный стабильный Xcode со Swift 6.2 или новее;
- VS Code с официальным расширением `swiftlang.swift-vscode`.

## Команды

```sh
swift build
swift test
swift run TamaChecks
swift run Tama
swift build -c release --product Tama -debug-info-format none
```

`swift run TamaChecks --strict-package` дополнительно проверяет требования упаковки v2, включая прозрачность неиспользуемых ячеек атласа.

В VS Code те же команды доступны через `Tasks: Run Task`.

## Рабочий процесс

Для разработки используются ветки `feature/<name>` и `fix/<name>`. Перед pull request необходимо запустить `swift test` и `swift build -c release --product Tama -debug-info-format none`. В `main` следует вливать только прошедшие проверки изменения.
