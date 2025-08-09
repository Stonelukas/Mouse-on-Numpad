# Theming and Colors

This project uses `ColorThemeManager` for themed colors and `ColorHelpers.ahk` for color utilities.

## ColorThemeManager API
- `ColorThemeManager.Initialize()`
- `ColorThemeManager.SetTheme(name)` / `ApplyTheme(name)`: Set active theme
- `ColorThemeManager.GetCurrentTheme()` -> string
- `ColorThemeManager.GetColor(key)` -> 0xRRGGBB
- `ColorThemeManager.GetContrastingColor(bgColor)` -> 0xRRGGBB text color
- `ColorThemeManager.GetThemeNames()` -> array of names
- `ColorThemeManager.GetThemeInfo(name?)` -> formatted string
- `ColorThemeManager.ExportCurrentTheme()` -> formatted string
- `ColorThemeManager.AddCustomTheme(name, colorsMap)` -> bool
- `ColorThemeManager.UpdateAllGUIs()`
- `ColorThemeManager.Cleanup()`

### Built-in color keys
`info, success, warning, error, background, text, inactive, accent`

### Example: Switch theme and apply to UI
```autohotkey
ColorThemeManager.SetTheme("Ocean")
StatusIndicator.Update()
TooltipSystem.ApplyTheme()
```

### Example: Add a custom theme
```autohotkey
myColors := {
  info: 0x3366FF,
  success: 0x22CC88,
  warning: 0xFFBB33,
  error: 0xFF4444,
  background: 0x101010,
  text: 0xFFFFFF,
  inactive: 0x777777,
  accent: 0x00E5FF
}
ColorThemeManager.AddCustomTheme("MyTheme", myColors)
ColorThemeManager.SetTheme("MyTheme")
```

## ColorHelpers (utility functions)
- `ConvertHexToRGB(hex)` -> `{r,g,b}`
- `GetContrastingColor(hex)` -> "0x000000" or "0xFFFFFF"
- `ConvertRGBToHex(r,g,b)` -> `0xRRGGBB`
- `LightenColor(hex, percent)` / `DarkenColor(hex, percent)`
- `MixColors(hex1, hex2, ratio)`

### Example: Ensure readable text
```autohotkey
bg := ColorThemeManager.GetColor("tooltipInfo")
text := ColorThemeManager.GetContrastingColor(bg)
; Use text as font color for best contrast
```