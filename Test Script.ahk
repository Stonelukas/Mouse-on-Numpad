#Requires AutoHotkey v2.0

; Test script to verify expression evaluation
; Press F12 to run this test

F12::{
    ; Test the expression evaluation function
    testExpressions := [
        "100",
        "A_ScreenHeight - 80",
        "Round(A_ScreenWidth * 0.65)",
        "A_ScreenWidth / 2",
        "200"
    ]
    
    result := "Expression Evaluation Test Results:`n`n"
    
    for expr in testExpressions {
        value := EvaluateExpression(expr)
        result .= expr . " = " . value . "`n"
    }
    
    ; Also show actual screen dimensions
    result .= "`nScreen Info:`n"
    result .= "A_ScreenWidth = " . A_ScreenWidth . "`n"
    result .= "A_ScreenHeight = " . A_ScreenHeight . "`n"
    
    MsgBox(result, "Expression Test", "i")
}

; Copy of the EvaluateExpression function from MonitorUtils
EvaluateExpression(expression) {
    try {
        if (expression = "A_ScreenHeight - 80") {
            return A_ScreenHeight - 80
        } else if (expression = "Round(A_ScreenWidth * 0.65)") {
            return Round(A_ScreenWidth * 0.65)
        } else if (IsNumber(expression)) {
            return Number(expression)
        } else {
            return %expression%
        }
    } catch {
        return 0
    }
}