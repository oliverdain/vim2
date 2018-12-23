// Oni config. Symlink to ~/.config/oni/config.js

const increaseFontSize = (oni) => {
    var currentFontSize = oni.configuration.getValue("editor.fontSize");

    var newFontSize = parseInt(currentFontSize) + 1;

    oni.configuration.setValues(
        {
            "editor.fontSize": newFontSize,
        }
    );
};

const decreaseFontSize = (oni) => {
    var currentFontSize = oni.configuration.getValue("editor.fontSize");

    var newFontSize = parseInt(currentFontSize) - 1;
    if (newFontSize < 2) {
       newFontSize = 2;
    }

    oni.configuration.setValues(
        {
            "editor.fontSize": newFontSize,
        }
    );
};

const activate = (oni) => {
    console.log("config activated")
   // Increase font size
   oni.input.bind("<c-=>", () => increaseFontSize(oni));
   // Decrease font size
   oni.input.bind("<c-->", () => decreaseFontSize(oni));
};

module.exports = {
   activate,
   "commandline.mode": false,
   "ui.colorscheme": "slate",
   "oni.loadInitVim": true,
   "autoClosingPairs.enabled": false,
   // UI customizations
   "ui.animations.enabled": true,
   "ui.fontSmoothing": "auto",
}
