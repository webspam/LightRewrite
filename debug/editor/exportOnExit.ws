/** Auto-export when exiting the game */
@wrapMethod(ConfirmationPopupData)
function OnUserFeedback(KeyCode: string) {
    wrappedMethod(KeyCode);

    if (m_TextContent != "Are you sure you want to quit? Any unsaved progress will be lost.") {
        return;
    }
    if (KeyCode != "enter-gamepad_A") return;

    LogChannel('LRDebug_AutoExport', "Starting auto-export...");
    LRDebug_ExportEditedLights('LRDebug_AutoExport');
}
