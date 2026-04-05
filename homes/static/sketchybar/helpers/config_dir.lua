-- SketchyBar config root (Nix links here via xdg.configFile."sketchybar").
return os.getenv("CONFIG_DIR") or (os.getenv("HOME") .. "/.config/sketchybar")
