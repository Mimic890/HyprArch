(() => {
    const elements = document.querySelectorAll(
        "h1, h2, h3, h4, h5, h6, p, a, .text, strong, span"
    );

    function clamp(num, min, max) {
        return Math.min(Math.max(num, min), max);
    }

    const fontSettings = {
        H1: { min: 24, max: 40, vwFactor: 0.015 },
        H2: { min: 20, max: 32, vwFactor: 0.012 },
        H3: { min: 18, max: 28, vwFactor: 0.010 },
        H4: { min: 16, max: 24, vwFactor: 0.008 },
        H5: { min: 14, max: 20, vwFactor: 0.007 },
        H6: { min: 12, max: 18, vwFactor: 0.006 },
        P: { min: 14, max: 18, vwFactor: 0.007 },
        A: { min: 14, max: 18, vwFactor: 0.007 },
        ".TEXT": { min: 14, max: 18, vwFactor: 0.007 },
        STRONG: { min: 12, max: 24, vwFactor: 0.06 },
        SPAN: { min: 12, max: 24, vwFactor: 0.06 },
    };

    function updateFontSizes() {
        const w = window.innerWidth;
        elements.forEach(el => {
            const tag = el.tagName;
            const className = el.className.toUpperCase();
            let key;

            if (fontSettings[tag]) {
                key = tag;
            } else if (className === "TEXT") {
                key = ".TEXT";
            } else {
                key = "P";
            }

            const { min, max, vwFactor } = fontSettings[key];
            const size = clamp(min + w * vwFactor, min, max);
            el.style.fontSize = size + "px";
        });
    }

    window.addEventListener("resize", updateFontSizes);
    window.addEventListener("load", updateFontSizes);
})();
