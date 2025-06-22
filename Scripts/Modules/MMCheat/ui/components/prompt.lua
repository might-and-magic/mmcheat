local iup = require("iup")
local i18n = require("MMCheat/i18n/i18n")
local ui = require("MMCheat/ui/components/ui_components")

-- Pop up a dialog with a text input field and a button. The button will be "OK" and the input field will have the label and the default value.
local function prompt(title, label, default_value, attrs)
	local ret

	local label_control = ui.label(label, {
		MAXSIZE = "600x",
		MINSIZE = "600x45",
		WORDWRAP = "YES"
	})
	local input = ui.input(default_value, {
		EXPAND = "HORIZONTAL"
	})

	local ok_button = ui.button(i18n._("ok"), nil, {
		MINSIZE = "80x"
	})
	local cancel_button = ui.button(i18n._("cancel"), nil, {
		MINSIZE = "80x"
	})
	local button_hbox = ui.button_hbox({ ok_button, cancel_button })
	local button_vbox = ui.centered_vbox(button_hbox)

	local content_vbox = ui.vbox({ label_control, input, button_vbox }, {
		ALIGNMENT = "ACENTER"
	})

	local dialog_callbacks = {}

	local dialog = ui.dialog(content_vbox, {
		TITLE = title,
		BRINGFRONT = "YES"
	})

	iup.SetCallback(input, "K_ANY", iup.cb.k_any(function(ih, c)
		table.insert(dialog_callbacks, ih)
		if c == iup.K_CR then
			ret = iup.GetAttribute(input, "VALUE")
			return iup.CLOSE
		elseif c == iup.K_ESC then
			return iup.CLOSE
		end
		return iup.DEFAULT
	end))

	iup.SetCallback(ok_button, "ACTION", function(ih)
		table.insert(dialog_callbacks, ih)
		ret = iup.GetAttribute(input, "VALUE")
		return iup.CLOSE
	end)

	iup.SetCallback(cancel_button, "ACTION", function(ih)
		table.insert(dialog_callbacks, ih)
		return iup.CLOSE
	end)

	-- Show dialog
	iup.Popup(dialog, iup.CENTER, iup.CENTER)

	-- Popup closes, free callbacks
	iup.FreeCallbacks(dialog_callbacks)

	return ret
end

return prompt
