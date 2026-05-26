#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
; Event mode stayed stable under heavy simultaneous typing.
SendMode "Event"
; Avoid AHK hotkey flood warnings during dense chord typing.
; These values do not participate in layout meaning/judgment.
A_HotkeyInterval := 2000
A_MaxHotkeysPerInterval := 2000

; =========================================================================
; L2.4.ahk - Fujin layout
; =========================================================================
; The script always runs as Fujin:
;   - Left-hand vowel/chord logic
;   - Left-hand Caps/Space layers
;   - Physical Y participates as consonant X
; Right-hand base typing stays native QWERTY.
; =========================================================================

SetCapsLockState "AlwaysOff"
OnExit CleanupBeforeExit

#SuspendExempt
!F9::ToggleScriptSuspend()
#SuspendExempt False
!F10::ToggleDebugLogging()
!F11::DebugMark("manual")
!F12::DebugDumpState("manual")

; --- Global State ---
; SpaceHeld keeps the Space flow alive until Space Up drains it.
; SpaceUsedAsModifier suppresses literal space output on Space Up.
Global SpaceHeld := false
Global SpaceUsedAsModifier := false
Global SpaceCapsBackspacePending := false
Global ThumbUUsed := false
Global LastVowelFromThumbU := false
; Typical Windows AHK scan code for Muhenkan (JIS 無変換). Adjust if needed per host.
Global ThumbUMuhenkanKey := "sc07B"
Global CapsActive := false
Global CapsImeRestorePending := false
Global CapsImeRestoreHwnd := 0
Global SpaceCapsMode := false
Global LastCharWasVowel := false
Global KeyDownMap := Map()
Global DebugEnabled := false
Global DebugLogPath := A_ScriptDir "\L2-debug.log"
Global DebugBuffer := []
Global DebugMaxEntries := 2000
Global LayoutTrayIconDir := A_ScriptDir "\tray-icons"
; Choose one preset name here:
; - "classic" = current Windows built-ins
; - "signal"  = green/red circles
; - "tile"    = cyan/orange rounded squares
; - "gem"     = teal/plum diamonds
; - "mono"    = dark/light monochrome circles
; - "sun"     = gold/navy circles
Global LayoutTrayPreset := "classic"
Global LayoutTrayPresets := Map(
    "classic", {
        on: {file: A_WinDir "\System32\shell32.dll", number: 3, tooltip: "L2.4: Fujin"},
        off: {file: A_WinDir "\System32\shell32.dll", number: 132, tooltip: "L2.4: Fujin"}
    },
    "signal", {
        on: {file: LayoutTrayIconDir "\signal-on.ico", number: 1, tooltip: "L2.4: Fujin"},
        off: {file: LayoutTrayIconDir "\signal-off.ico", number: 1, tooltip: "L2.4: Fujin"}
    },
    "tile", {
        on: {file: LayoutTrayIconDir "\tile-on.ico", number: 1, tooltip: "L2.4: Fujin"},
        off: {file: LayoutTrayIconDir "\tile-off.ico", number: 1, tooltip: "L2.4: Fujin"}
    },
    "gem", {
        on: {file: LayoutTrayIconDir "\gem-on.ico", number: 1, tooltip: "L2.4: Fujin"},
        off: {file: LayoutTrayIconDir "\gem-off.ico", number: 1, tooltip: "L2.4: Fujin"}
    },
    "mono", {
        on: {file: LayoutTrayIconDir "\mono-on.ico", number: 1, tooltip: "L2.4: Fujin"},
        off: {file: LayoutTrayIconDir "\mono-off.ico", number: 1, tooltip: "L2.4: Fujin"}
    },
    "sun", {
        on: {file: LayoutTrayIconDir "\sun-on.ico", number: 1, tooltip: "L2.4: Fujin"},
        off: {file: LayoutTrayIconDir "\sun-off.ico", number: 1, tooltip: "L2.4: Fujin"}
    }
)

ApplyLayoutModeVisuals(false)

; Core invariants:
; - This file is currently on the stable "no timing-based meaning" path.
; - `SendMode "Event"` is part of that stable path and should not be changed casually.
; - KeyDownMap tracks left-hand char keys currently treated as held.
; - Left-hand repeat down events are ignored intentionally.
; - Hot-path KeyDownMap mutations should go through TryTrackCharKeyDown/UntrackCharKey.
; - SpaceHeld keeps the current Space sequence alive until Space Up drains it.
; - SpaceUsedAsModifier suppresses literal space output on Space Up.
; - SpaceCapsMode and SpaceCapsBackspacePending are chord-scoped, not long-lived.
; - LastVowelFromThumbU implies LastCharWasVowel.

ResetTransientState() {
    global KeyDownMap

    ; Suspends/resumes can leave key-up dependent state behind, so clear
    ; transient typing state whenever the script state changes.
    ClearSpaceState()
    ClearSpaceCapsState()
    ClearThumbUState()
    ResetLastOutputState()
    KeyDownMap.Clear()
}

CleanupBeforeExit(*) {
    ResetTransientState()
}

DebugLog(message) {
    global DebugEnabled, DebugBuffer, DebugMaxEntries
    if !DebugEnabled
        return
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    DebugBuffer.Push(timestamp "." A_MSec " " message)
    while (DebugBuffer.Length > DebugMaxEntries)
        DebugBuffer.RemoveAt(1)
}

DebugLogParts(parts*) {
    global DebugEnabled
    if !DebugEnabled
        return
    message := ""
    for _, part in parts
        message .= part
    DebugLog(message)
}

DebugMark(reason := "") {
    DebugLogParts("=== mark ", reason, " ===")
}

ToggleDebugLogging() {
    global DebugEnabled, DebugBuffer
    DebugEnabled := !DebugEnabled
    if DebugEnabled {
        DebugBuffer := []
        DebugLog("=== debug enabled ===")
    }
    ToolTip DebugEnabled ? "L2 debug on" : "L2 debug off"
    SetTimer () => ToolTip(), -1000
}

DebugDumpState(reason := "") {
    global DebugEnabled, DebugLogPath, DebugBuffer
    global SpaceHeld, SpaceUsedAsModifier
    global SpaceCapsBackspacePending, SpaceCapsMode, ThumbUUsed
    global LastVowelFromThumbU, LastCharWasVowel
    global KeyDownMap

    snapshot := "reason=" reason
        . " debugEnabled=" DebugEnabled
        . " physSpace=" GetKeyState("Space", "P")
        . " spaceHeld=" SpaceHeld
        . " spaceUsed=" SpaceUsedAsModifier
        . " spaceCapsPending=" SpaceCapsBackspacePending
        . " spaceCapsMode=" SpaceCapsMode
        . " thumbU=" ThumbUUsed
        . " lastThumbU=" LastVowelFromThumbU
        . " lastVowel=" LastCharWasVowel
        . " keyDownCount=" KeyDownMap.Count

    FileAppend "`n=== L2 debug dump ===`n" snapshot "`n", DebugLogPath, "UTF-8"
    if DebugEnabled {
        for _, line in DebugBuffer
            FileAppend line "`n", DebugLogPath, "UTF-8"
    } else {
        FileAppend "(debug buffer disabled)`n", DebugLogPath, "UTF-8"
    }
    FileAppend "=== end dump ===`n", DebugLogPath, "UTF-8"
}

ApplyLayoutModeVisuals(showToolTip := true) {
    global LayoutTrayPresets

    iconSpec := ResolveLayoutTrayIconSpec("on")
    TraySetIcon iconSpec.file, iconSpec.number
    if !showToolTip
        return
    ToolTip iconSpec.tooltip
    SetTimer () => ToolTip(), -2000
}

ResolveLayoutTrayIconSpec(mode) {
    global LayoutTrayPreset, LayoutTrayPresets

    presetName := LayoutTrayPresets.Has(LayoutTrayPreset) ? LayoutTrayPreset : "classic"
    iconSpec := LayoutTrayPresets[presetName].%mode%
    if FileExist(iconSpec.file)
        return iconSpec
    return LayoutTrayPresets["classic"].%mode%
}

ToggleScriptSuspend() {
    if A_IsSuspended {
        Suspend false
        ResetTransientState()
        ApplyLayoutModeVisuals()
        ToolTip "L2: resumed"
        SetTimer () => ToolTip(), -2000
        return
    }

    ResetTransientState()
    ToolTip "L2: suspended"
    SetTimer () => ToolTip(), -2000
    Suspend true
}

; --- Fujin Key Definitions (left hand) ---
; If you add or remove a char key, update:
; - CharKeyOrder
; - KeyMap / CapsLockMap / related layer maps as needed
; - left-hand down/up hotkeys below
; - lu1-raw-diagnose.ahk monitored keys if raw diagnosis should include it

Global CharKeyOrder := ["q", "w", "e", "r", "t", "y", "a", "s", "d", "f", "g", "z", "x", "c", "v", "b"]
Global CharKeyPriority := CreateCharKeyPriority(CharKeyOrder)

Global KeyMap := Map(
    "q", {normal: "m", vowel: "e"},
    "w", {normal: "y", vowel: "i"},
    "e", {normal: "r", vowel: "o"},
    "r", {normal: "w", vowel: "a"},
    "t", {normal: "p", vowel: "a"},
    "y", {normal: "x", vowel: "a"},
    "a", {normal: "k", vowel: "e", isVowelRow: true},
    "s", {normal: "s", vowel: "i", isVowelRow: true},
    "d", {normal: "t", vowel: "o", isVowelRow: true},
    "f", {normal: "n", vowel: "a", isVowelRow: true},
    "g", {normal: "h", vowel: "a", heldOutput: "-"},
    "z", {normal: "z", vowel: "e"},
    "x", {normal: "d", vowel: "i"},
    "c", {normal: "b", vowel: "o", spaceVowel: "u", comboVowel: "u"},
    "v", {normal: "g", vowel: "a"},
    "b", {normal: "j", vowel: "a", spaceVowel: "u"}
)

Global CapsLockMap := Map(
    "q", "f",  "w", "v",  "e", "c",  "r", "q",  "t", "l",
    "y", "x",
    "a", "g",  "s", "sh", "d", "th", "f", "h",
    "z", "/"
)

Global SpaceCapsMap := Map(
    "q", "<", "w", ">", "s", "sh", "z", "{?}"
)

Global SpaceSymbolMap := Map(
    "q", {char: "[", shift: "'"},
    "w", {char: "]", shift: '"'},
    "e", {char: ","},
    "r", {char: "."},
    "g", {char: "-"},
    "t", {char: "="},
    "b", {char: "{+}"},
    "v", {char: "_"},
    "z", {char: "'"},
    "x", {char: '"'}
)

Global CapsSpecialMap := Map(
    "1", "{^}", "2", "&", "3", "*", "4", "(", "5", ")",
    "F1", "{F11}", "F2", "{F12}", "F3", "{Insert}", "F4", "{PrintScreen}"
)

Global LeftCapsArrowMap := Map(
    "a", "{Left}",
    "s", "{Up}",
    "d", "{Down}",
    "f", "{Right}"
)

; --- Helper Functions ---

IsCtrlOrWinHeld() {
    return GetKeyState("LCtrl", "P") || GetKeyState("RCtrl", "P")
        || GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
}

IsThumbUPhysicallyHeld() {
    global ThumbUMuhenkanKey
    return GetKeyState("LAlt", "P") || GetKeyState(ThumbUMuhenkanKey, "P")
}

BuildThumbUReleasePrefix() {
    global ThumbUMuhenkanKey
    releasePrefix := ""
    if GetKeyState("LAlt", "P")
        releasePrefix .= "{LAlt Up}"
    if GetKeyState(ThumbUMuhenkanKey, "P")
        releasePrefix .= "{" ThumbUMuhenkanKey " Up}"
    return releasePrefix
}

IsModifierHeld(thumbUIsHeld := -1) {
    global ThumbUUsed
    if (thumbUIsHeld == -1)
        thumbUIsHeld := IsThumbUPhysicallyHeld()
    ; Keep predicates side-effect-free; cleanup lives in SyncInputState()/key-up paths.
    return IsCtrlOrWinHeld()
        || (thumbUIsHeld && !ThumbUUsed) || GetKeyState("RAlt", "P")
}

IsSpacePhysicallyHeld(spaceIsHeld := -1) {
    return (spaceIsHeld == -1) ? GetKeyState("Space", "P") : spaceIsHeld
}

LeftCharDownHotkeysActive() {
    return !IsCtrlOrWinHeld()
}

SpaceDownHotkeyActive() {
    return !IsModifierHeld()
}

SpaceUpHotkeyActive() {
    return true
}

SpaceNumberLayerActive() {
    return IsSpacePhysicallyHeld() && !IsModifierHeld()
}

ReadPhysicalState(&thumbUIsHeld, &spaceIsHeld, &capsIsHeld) {
    thumbUIsHeld := IsThumbUPhysicallyHeld()
    spaceIsHeld := GetKeyState("Space", "P")
    capsIsHeld := GetKeyState("CapsLock", "P")
}

ClearCapsImeRestoreState() {
    global CapsImeRestorePending, CapsImeRestoreHwnd

    CapsImeRestorePending := false
    CapsImeRestoreHwnd := 0
}

; IMEs can consume Shift+CapsLock, so send a suppressed Shift up-event only
; to the IME path before we apply our own Caps toggle.
SendSuppressedKeyUp(keyName) {
    vk := GetKeyVK(keyName)
    sc := GetKeySC(keyName)
    if !vk
        return
    DllCall("keybd_event"
        , "UInt", vk
        , "UInt", sc
        , "UInt", 0x2
        , "UPtr", 0xFFC3D450)
}

SuppressShiftCapsImeShortcut() {
    if GetKeyState("LShift", "P")
        SendSuppressedKeyUp("LShift")
    if GetKeyState("RShift", "P")
        SendSuppressedKeyUp("RShift")
}

GetImeOpenStatus(hwnd := 0) {
    if !hwnd
        hwnd := WinActive("A")
    if !hwnd
        return ""
    himc := DllCall("Imm32\ImmGetContext", "Ptr", hwnd, "Ptr")
    if !himc
        return ""
    isOpen := !!DllCall("Imm32\ImmGetOpenStatus", "Ptr", himc)
    DllCall("Imm32\ImmReleaseContext", "Ptr", hwnd, "Ptr", himc)
    return isOpen
}

SetImeOpenStatus(isOpen, hwnd := 0) {
    if !hwnd
        hwnd := WinActive("A")
    if !hwnd
        return false
    himc := DllCall("Imm32\ImmGetContext", "Ptr", hwnd, "Ptr")
    if !himc
        return false
    result := !!DllCall("Imm32\ImmSetOpenStatus", "Ptr", himc, "Int", !!isOpen)
    DllCall("Imm32\ImmReleaseContext", "Ptr", hwnd, "Ptr", himc)
    return result
}

DisableImeForCaps() {
    global CapsImeRestorePending, CapsImeRestoreHwnd

    ClearCapsImeRestoreState()
    hwnd := WinActive("A")
    if !hwnd
        return
    if (GetImeOpenStatus(hwnd) != true)
        return
    if !SetImeOpenStatus(false, hwnd)
        return
    CapsImeRestorePending := true
    CapsImeRestoreHwnd := hwnd
}

RestoreImeAfterCaps() {
    global CapsImeRestorePending, CapsImeRestoreHwnd

    if !CapsImeRestorePending
        return
    if (WinActive("A") = CapsImeRestoreHwnd)
        SetImeOpenStatus(true, CapsImeRestoreHwnd)
    ClearCapsImeRestoreState()
}

ToggleImeForActiveWindow() {
    hwnd := WinActive("A")
    if !hwnd
        return
    isOpen := GetImeOpenStatus(hwnd)
    if (isOpen == "")
        return
    SetImeOpenStatus(!isOpen, hwnd)
}

CleanupStaleTrackedKeys() {
    global KeyDownMap

    staleKeys := []
    for physKey, _ in KeyDownMap {
        if !GetKeyState(physKey, "P")
            staleKeys.Push(physKey)
    }
    for _, physKey in staleKeys {
        UntrackCharKey(physKey)
        DebugLogParts("sync cleanup key=", physKey, " keyDownCount=", KeyDownMap.Count)
    }
}

DrainReleasedTransientState(thumbUIsHeld, spaceIsHeld, capsIsHeld) {
    global SpaceUsedAsModifier

    if !thumbUIsHeld
        ClearThumbUState()

    if !spaceIsHeld {
        if SpaceUsedAsModifier
            ClearSpaceState()
        if !capsIsHeld
            ClearSpaceCapsState()
    }
}

SyncInputState() {
    ReadPhysicalState(&thumbUIsHeld, &spaceIsHeld, &capsIsHeld)

    CleanupStaleTrackedKeys()
    DrainReleasedTransientState(thumbUIsHeld, spaceIsHeld, capsIsHeld)
}

SyncAndReadPhysicalState(&thumbUIsHeld, &spaceIsHeld, &capsIsHeld) {
    SyncInputState()
    ReadPhysicalState(&thumbUIsHeld, &spaceIsHeld, &capsIsHeld)
}

HandleLeftKey(physKey) {
    SyncAndReadPhysicalState(&thumbUIsHeld, &spaceIsHeld, &capsIsHeld)
    modifierHeld := IsModifierHeld(thumbUIsHeld)
    DebugLogParts("left down key=", physKey
        , " physSpace=", spaceIsHeld
        , " spaceHeld=", SpaceHeld)

    if modifierHeld {
        SendBlindChar(physKey)
        return
    }

    if capsIsHeld {
        HandleCapsHeldLeftKey(physKey, spaceIsHeld, capsIsHeld)
        return
    }

    HandleKeyDown(physKey, spaceIsHeld, capsIsHeld)
}

FindCharKeyDown(ExcludeKey := "", StateIsFresh := false) {
    global CharKeyPriority, KeyDownMap
    if !StateIsFresh
        SyncInputState()
    if !HasTrackedCharDown(ExcludeKey, true)
        return ""
    bestKey := ""
    bestPriority := 999
    for physKey, _ in KeyDownMap {
        if (physKey == ExcludeKey)
            continue
        priority := CharKeyPriority[physKey]
        if (priority < bestPriority) {
            bestPriority := priority
            bestKey := physKey
        }
    }
    return bestKey
}

HasTrackedCharDown(ExcludeKey := "", StateIsFresh := false) {
    global KeyDownMap
    if !StateIsFresh
        SyncInputState()
    if (ExcludeKey == "")
        return KeyDownMap.Count > 0
    if !KeyDownMap.Has(ExcludeKey)
        return KeyDownMap.Count > 0
    return KeyDownMap.Count > 1
}

AnyPhysicalCharKeyDown(ExcludeKey := "") {
    global CharKeyOrder
    for _, physKey in CharKeyOrder {
        if (physKey != ExcludeKey && GetKeyState(physKey, "P"))
            return true
    }
    return false
}

CreateCharKeyPriority(charKeyOrder) {
    priority := Map()
    for index, physKey in charKeyOrder
        priority[physKey] := index
    return priority
}

TryTrackCharKeyDown(physKey, repeatLabel := "down") {
    global KeyDownMap
    if KeyDownMap.Has(physKey) {
        DebugLogParts("ignore repeat ", repeatLabel, " key=", physKey)
        return false
    }
    KeyDownMap[physKey] := true
    return true
}

UntrackCharKey(physKey) {
    global KeyDownMap
    if KeyDownMap.Has(physKey)
        KeyDownMap.Delete(physKey)
}

ApplyCaseAndSend(char) {
    global ThumbUUsed
    if ThumbUUsed {
        releasePrefix := BuildThumbUReleasePrefix()
        if GetKeyState("Shift", "P")
            Send releasePrefix "+" char
        else
            Send releasePrefix char
    } else {
        ; CapsLock+z resolves to "/" and physical Shift turns it into "?".
        ; Sending that via {Blind} can leave CapsLock logically stuck afterward,
        ; so emit the literal character directly on this path.
        if (char == "/" && GetKeyState("Shift", "P")) {
            SendLiteralText("?")
            return
        }
        Send "{Blind}" char
    }
}

SendWithoutShift(char) {
    Send "{LShift Up}{RShift Up}" char
}

SendLiteralText(text) {
    SendText text
}

SendBlindChar(char) {
    Send "{Blind}" char
}

ClearSpaceState() {
    global SpaceHeld, SpaceUsedAsModifier
    SpaceHeld := false
    SpaceUsedAsModifier := false
}

ClearSpaceCapsPending() {
    global SpaceCapsBackspacePending
    SpaceCapsBackspacePending := false
}

ClearSpaceCapsState() {
    global SpaceCapsMode
    ClearSpaceCapsPending()
    SpaceCapsMode := false
}

ClearThumbUState() {
    global ThumbUUsed
    ThumbUUsed := false
}

BeginThumbUOutput() {
    global ThumbUUsed
    ThumbUUsed := true
    SetLastOutputState(true, true)
}

MarkSpaceAsModifier() {
    global SpaceHeld, SpaceUsedAsModifier
    SpaceHeld := true
    SpaceUsedAsModifier := true
}

SetSpaceTapPending() {
    global SpaceHeld, SpaceUsedAsModifier
    SpaceHeld := true
    SpaceUsedAsModifier := false
}

SpaceModSend(output) {
    MarkSpaceAsModifier()
    Send output
}

ResolveVowel(physKey, spaceIsHeld) {
    if !KeyMap.Has(physKey)
        return ""
    targetVowel := KeyMap[physKey].vowel
    if (spaceIsHeld && KeyMap[physKey].HasProp("spaceVowel"))
        targetVowel := KeyMap[physKey].spaceVowel
    return targetVowel
}

SetLastOutputState(isVowel, fromThumbU := false) {
    global LastCharWasVowel, LastVowelFromThumbU

    LastCharWasVowel := isVowel
    LastVowelFromThumbU := isVowel && fromThumbU
}

ResetLastOutputState() {
    SetLastOutputState(false)
}

TryResolveHeldOutput(physKey, allowVowelCarry := false) {
    global LastVowelFromThumbU, LastCharWasVowel

    if !KeyMap.Has(physKey) || !KeyMap[physKey].HasProp("heldOutput")
        return ""

    if LastVowelFromThumbU {
        if (allowVowelCarry || IsThumbUPhysicallyHeld()) {
            ResetLastOutputState()
            ; Thumb-U generated u only carries into held-output while the chord is
            ; still alive via that key itself or another held char key.
            return KeyMap[physKey].heldOutput
        }
        ResetLastOutputState()
    }
    if allowVowelCarry && LastCharWasVowel {
        ResetLastOutputState()
        return KeyMap[physKey].heldOutput
    }
    return ""
}

ResolveTypedChar(physKey, heldCharKey, spaceIsHeld) {
    if !KeyMap.Has(physKey)
        return ""

    isVowelRow := KeyMap[physKey].HasProp("isVowelRow")
    comboVowelMode := !spaceIsHeld && heldCharKey != "" && KeyMap[physKey].HasProp("comboVowel")
    vowelMode := spaceIsHeld || comboVowelMode || (heldCharKey != "" && isVowelRow)
    if vowelMode {
        SetLastOutputState(true)
        if comboVowelMode
            return KeyMap[physKey].comboVowel
        return ResolveVowel(physKey, spaceIsHeld)
    }

    char := TryResolveHeldOutput(physKey, heldCharKey != "")
    if (char != "")
        return char

    ResetLastOutputState()
    return KeyMap[physKey].normal
}

ResolveCapsStandaloneChar(physKey) {
    char := TryResolveHeldOutput(physKey, true)
    if (char != "")
        return char

    ResetLastOutputState()
    if CapsLockMap.Has(physKey)
        return CapsLockMap[physKey]
    if KeyMap.Has(physKey)
        return KeyMap[physKey].normal
    return ""
}

TryApplyResolvedCaseChar(char) {
    if (char == "")
        return false
    ApplyCaseAndSend(char)
    return true
}

TryHandleStandaloneCapsOutput(physKey, capsIsHeld) {
    global CapsLockMap

    if !(capsIsHeld && CapsLockMap.Has(physKey) && !HasTrackedCharDown(physKey, true))
        return false
    ApplyCaseAndSend(CapsLockMap[physKey])
    return true
}

TryHandleSpaceSymbolOutput(physKey, spaceIsHeld) {
    global SpaceSymbolMap

    if !(spaceIsHeld && SpaceSymbolMap.Has(physKey))
        return false
    mapping := SpaceSymbolMap[physKey]
    if mapping.HasProp("shift") && GetKeyState("Shift", "P") {
        SendWithoutShift(mapping.shift)
        return true
    }
    Send mapping.char
    return true
}

TryHandleSpaceCapsOutput(physKey) {
    global SpaceCapsMode, SpaceCapsMap
    if !(SpaceCapsMode && SpaceCapsMap.Has(physKey))
        return false
    MarkSpaceAsModifier()
    mappedChar := SpaceCapsMap[physKey]
    ; `?` via `{Blind}{?}` can leave the CapsLock chord path in a logically-held
    ; state after the chord. Send literal text instead so no extra modifier
    ; synthesis/restoration is involved.
    if (mappedChar == "{?}") {
        SendLiteralText("?")
        return true
    }
    ApplyCaseAndSend(mappedChar)
    return true
}

HandleCapsHeldLeftKey(physKey, spaceIsHeld, capsIsHeld) {
    global LeftCapsArrowMap, KeyMap

    if LeftCapsArrowMap.Has(physKey) {
        HandleCapsArrow(physKey, LeftCapsArrowMap[physKey], spaceIsHeld, capsIsHeld)
        return
    }
    if KeyMap.Has(physKey) {
        HandleCapsKey(physKey, spaceIsHeld, capsIsHeld)
        return
    }
    SendBlindChar(physKey)
}

; --- Main Character Processor (left hand) ---
; Caller is expected to sync once and pass the same physical-state snapshot down.

ProcessChar(physKey, spaceIsHeld := -1, capsIsHeld := -1) {
    spaceIsHeld := IsSpacePhysicallyHeld(spaceIsHeld)

    ; Mark Space as modifier early (applies to all Space-held paths)
    if spaceIsHeld
        MarkSpaceAsModifier()

    ; 1. CapsLock layer (first key only)
    if TryHandleStandaloneCapsOutput(physKey, capsIsHeld) {
        return
    }

    ; 2. Space layer (symbols)
    if TryHandleSpaceSymbolOutput(physKey, spaceIsHeld) {
        return
    }
    ; 4. Vowel coding
    heldCharKey := FindCharKeyDown(physKey, true)
    char := ResolveTypedChar(physKey, heldCharKey, spaceIsHeld)
    TryApplyResolvedCaseChar(char)
}

TryHandleSpaceShiftEnter() {
    if !GetKeyState("LShift", "P")
        return false
    Send "{LShift Up}{Enter}"
    return true
}

TryHandleSpaceHeldVowel(heldKey) {
    if (heldKey == "")
        return false
    vowel := ResolveVowel(heldKey, false)
    DebugLogParts("space vowel heldKey=", heldKey, " vowel=", vowel)
    ; Reverse-rollover vowels should also enable the following held-output `-`.
    SetLastOutputState(true)
    ApplyCaseAndSend(vowel)
    MarkSpaceAsModifier()
    return true
}

TryEmitPendingLiteralSpace() {
    global SpaceHeld, SpaceUsedAsModifier

    if !(SpaceHeld && !SpaceUsedAsModifier)
        return false
    Send "{Space}"
    return true
}

HandleKeyDown(physKey, spaceIsHeld := -1, capsIsHeld := -1) {
    if !TryTrackCharKeyDown(physKey) {
        return
    }
    ProcessChar(physKey, spaceIsHeld, capsIsHeld)
}

HandleKeyUp(physKey) {
    UntrackCharKey(physKey)
    DebugLogParts("left up key=", physKey, " keyDownCount=", KeyDownMap.Count)
}

HandleCapsKey(physKey, spaceIsHeld := -1, capsIsHeld := -1) {
    if !TryTrackCharKeyDown(physKey, "caps down") {
        return
    }
    ClearSpaceCapsPending()
    ; Space-Caps chord path: special mappings
    if TryHandleSpaceCapsOutput(physKey) {
        return
    }
    if HasTrackedCharDown(physKey, true) {
        ProcessChar(physKey, spaceIsHeld, capsIsHeld)
        return
    }
    TryApplyResolvedCaseChar(ResolveCapsStandaloneChar(physKey))
}

HandleCapsArrow(physKey, arrow, spaceIsHeld := -1, capsIsHeld := -1) {
    ClearSpaceCapsPending()
    ; Space-Caps chord path takes priority when active.
    if TryHandleSpaceCapsOutput(physKey) {
        return
    }
    if !HasTrackedCharDown(physKey, true)
        Send "{Blind}" arrow
    else
        HandleCapsKey(physKey, spaceIsHeld, capsIsHeld)
}

HandleCapsBacktick() {
    if GetKeyState("Shift", "P")
        SendWithoutShift("|")
    else
        Send "\"
}

BeginReverseSpaceCapsCombo() {
    global SpaceCapsBackspacePending, SpaceCapsMode
    if !IsSpacePhysicallyHeld()
        return
    SpaceCapsMode := true
    SpaceCapsBackspacePending := !HasTrackedCharDown(, true)
    if SpaceCapsBackspacePending
        MarkSpaceAsModifier()
}

HandleCapsComboKey(physKey) {
    SyncAndReadPhysicalState(&thumbUIsHeld, &spaceIsHeld, &capsIsHeld)
    HandleCapsHeldLeftKey(physKey, spaceIsHeld, true)
}

HandleCapsComboSpace() {
    ClearSpaceCapsPending()
    MarkSpaceAsModifier()
    Send "{Backspace}"
}

HandleThumbUDown() {
    global ThumbUUsed
    if ThumbUUsed
        return
    BeginThumbUOutput()
    Send "u"
}

HandleThumbUUp() {
    if !IsThumbUPhysicallyHeld()
        ClearThumbUState()
}

ToggleCapsActiveState() {
    global CapsActive

    SuppressShiftCapsImeShortcut()
    CapsActive := !CapsActive
    if CapsActive {
        DisableImeForCaps()
        SetCapsLockState "AlwaysOn"
    } else {
        SetCapsLockState "AlwaysOff"
        RestoreImeAfterCaps()
    }
    ToolTip CapsActive ? "CAPS ON" : "CAPS OFF"
    SetTimer () => ToolTip(), -1000
}

HandleSpaceDown() {
    global SpaceCapsMode, SpaceUsedAsModifier
    SyncAndReadPhysicalState(&thumbUIsHeld, &spaceIsHeld, &capsIsHeld)
    DebugLogParts("space down physSpace=", spaceIsHeld
        , " spaceHeld=", SpaceHeld
        , " spaceUsed=", SpaceUsedAsModifier)

    if SpaceCapsMode
        return
    heldKey := FindCharKeyDown(, true)
    if TryHandleSpaceShiftEnter()
        return
    if TryHandleSpaceHeldVowel(heldKey)
        return

    SetSpaceTapPending()
    DebugLog("space hold-start")
}

HandleSpaceUp() {
    spaceIsHeld := GetKeyState("Space", "P")
    DebugLogParts("space up physSpace=", spaceIsHeld
        , " spaceHeld=", SpaceHeld
        , " spaceUsed=", SpaceUsedAsModifier)
    if SpaceCapsBackspacePending
        Send "{Backspace}"
    TryEmitPendingLiteralSpace()
    ClearSpaceState()
    ClearSpaceCapsState()
    DebugLog("space up cleared state")
}

HandleSpaceBacktick() {
    if GetKeyState("Shift", "P")
        SpaceModSend("{LShift Up}{RShift Up};")
    else
        SpaceModSend(":")
}

HandleBaseBacktickKey() {
    if GetKeyState("Shift", "P")
        SendLiteralText("~")
    else
        SendLiteralText("``")
}

; *****************************************************************
;  SECTION 1: Fujin Layout
; *****************************************************************

; `sc029` is the physical key at the top-left letter row position.
; On US keyboards this is the `~/` key. On JIS keyboards this is the
; 半角/全角/漢字 key, which we intentionally treat as the US backtick key.
#HotIf !IsModifierHeld() && !IsSpacePhysicallyHeld()
*sc029::HandleBaseBacktickKey()
#HotIf

; CapsLock chords are handled as direct custom combinations so they do not
; depend on CapsLock-down/up state tracking.
+CapsLock::ToggleCapsActiveState()
CapsLock::return

; If Space is pressed first, mark the Space+Caps path so the following
; CapsLock chord behaves the same as the Caps-first path.
#HotIf IsSpacePhysicallyHeld() && !IsCtrlOrWinHeld()
~*CapsLock::BeginReverseSpaceCapsCombo()

#HotIf !IsCtrlOrWinHeld()
CapsLock & 1::Send CapsSpecialMap["1"]
CapsLock & 2::Send CapsSpecialMap["2"]
CapsLock & 3::Send CapsSpecialMap["3"]
CapsLock & 4::Send CapsSpecialMap["4"]
CapsLock & 5::Send CapsSpecialMap["5"]
CapsLock & F1::Send CapsSpecialMap["F1"]
CapsLock & F2::Send CapsSpecialMap["F2"]
CapsLock & F3::Send CapsSpecialMap["F3"]
CapsLock & F4::Send CapsSpecialMap["F4"]
CapsLock & sc029::HandleCapsBacktick()
CapsLock & q::HandleCapsComboKey("q")
CapsLock & w::HandleCapsComboKey("w")
CapsLock & e::HandleCapsComboKey("e")
CapsLock & r::HandleCapsComboKey("r")
CapsLock & t::HandleCapsComboKey("t")
CapsLock & y::HandleCapsComboKey("y")
CapsLock & a::HandleCapsComboKey("a")
CapsLock & s::HandleCapsComboKey("s")
CapsLock & d::HandleCapsComboKey("d")
CapsLock & f::HandleCapsComboKey("f")
CapsLock & g::HandleCapsComboKey("g")
CapsLock & z::HandleCapsComboKey("z")
CapsLock & x::HandleCapsComboKey("x")
CapsLock & c::HandleCapsComboKey("c")
CapsLock & v::HandleCapsComboKey("v")
CapsLock & b::HandleCapsComboKey("b")
CapsLock & Space::HandleCapsComboSpace()
CapsLock & LAlt::HandleThumbUDown()
CapsLock & sc07B::HandleThumbUDown()
#HotIf

; Ctrl/Win shortcuts bypass the left-hand layer entirely.
#HotIf LeftCharDownHotkeysActive()
$*q::HandleLeftKey("q")
$*w::HandleLeftKey("w")
$*e::HandleLeftKey("e")
$*r::HandleLeftKey("r")
$*t::HandleLeftKey("t")
$*y::HandleLeftKey("y")
$*a::HandleLeftKey("a")
$*s::HandleLeftKey("s")
$*d::HandleLeftKey("d")
$*f::HandleLeftKey("f")
$*g::HandleLeftKey("g")
$*z::HandleLeftKey("z")
$*x::HandleLeftKey("x")
$*c::HandleLeftKey("c")
$*v::HandleLeftKey("v")
$*b::HandleLeftKey("b")
#HotIf

; --- Left hand key UP ---
; Intentionally global (outside #HotIf): keeps left-hand state consistent even
; when modifiers are pressed/released mid-keystroke. ~ prefix lets native key-up
; pass through, and SyncInputState() cleans up anything stale on the next event.
~$*q Up::HandleKeyUp("q")
~$*w Up::HandleKeyUp("w")
~$*e Up::HandleKeyUp("e")
~$*r Up::HandleKeyUp("r")
~$*t Up::HandleKeyUp("t")
~$*y Up::HandleKeyUp("y")
~$*a Up::HandleKeyUp("a")
~$*s Up::HandleKeyUp("s")
~$*d Up::HandleKeyUp("d")
~$*f Up::HandleKeyUp("f")
~$*g Up::HandleKeyUp("g")
~$*z Up::HandleKeyUp("z")
~$*x Up::HandleKeyUp("x")
~$*c Up::HandleKeyUp("c")
~$*v Up::HandleKeyUp("v")
~$*b Up::HandleKeyUp("b")

; *****************************************************************
;  SECTION 3: Special Keys
; *****************************************************************

; --- CharKey + Thumb-U key (LAlt / Muhenkan) = u ---
#HotIf AnyPhysicalCharKeyDown() && !IsCtrlOrWinHeld()
*LAlt::HandleThumbUDown()
*sc07B::HandleThumbUDown()
#HotIf

; --- Thumb-U catch-all: ensure native passthrough ---
~*LAlt::return
~*sc07B::return

; --- Thumb-U Up: reset flag ---
~*LAlt Up::HandleThumbUUp()
~*sc07B Up::HandleThumbUUp()

; --- Space key ---
#HotIf SpaceDownHotkeyActive()
$*Space::HandleSpaceDown()
#HotIf

#HotIf SpaceUpHotkeyActive()
; --- Space Up: reset state only while layout is active or draining prior state ---
$*Space Up::HandleSpaceUp()
#HotIf

; --- LCtrl+Space = Delete / LCtrl+sc029 = IME toggle ---
#HotIf
<^Space::Send "{Delete}"
<^sc029::ToggleImeForActiveWindow()

; --- Space + number row ---
#HotIf SpaceNumberLayerActive()
*1::SpaceModSend("6")
*2::SpaceModSend("7")
*3::SpaceModSend("8")
*4::SpaceModSend("9")
*5::SpaceModSend("0")
*F1::SpaceModSend("{F6}")
*F2::SpaceModSend("{F7}")
*F3::SpaceModSend("{F8}")
*F4::SpaceModSend("{F9}")
*F5::SpaceModSend("{F10}")
*sc029::HandleSpaceBacktick()
#HotIf
