local theme = require("modules/theme")

hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 10,
        border_size      = 0,
        ["col.active_border"] = "rgb(" .. theme.accent:gsub("#", "") .. ")",
        ["col.inactive_border"] = "rgb(" .. theme.bgAlt:gsub("#", "") .. ")",
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = 12,
        rounding_power   = 2,
        active_opacity   = 1.0,
        inactive_opacity = 0.3,
        shadow           = {
            enabled      = false
        },
        blur             = {
            enabled  = true,
            size     = 1,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },
})
