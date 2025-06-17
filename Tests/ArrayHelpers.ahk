; ######################################################################################################################
; FILE: Tests/ArrayHelpers.ahk - Helper functions for array operations in v2
; ######################################################################################################################

#Requires AutoHotkey v2.0

; Join array elements into a string
ArrayJoin(arr, separator := ", ") {
    result := ""
    for i, item in arr {
        if (i > 1) {
            result .= separator
        }
        result .= String(item)
    }
    return result
}

; Alternative: Extend Array prototype (use with caution)
; This adds a Join method to all arrays
class Array {
    Join(separator := ", ") {
        return ArrayJoin(this, separator)
    }
}

; Check if array contains a value
ArrayContains(arr, value) {
    for item in arr {
        if (item = value) {
            return true
        }
    }
    return false
}

; Get array as formatted string for debugging
ArrayToString(arr) {
    if (arr.Length = 0) {
        return "[]"
    }
    return "[" . ArrayJoin(arr, ", ") . "]"
}

; Filter array based on condition
ArrayFilter(arr, conditionFunc) {
    result := []
    for item in arr {
        if (conditionFunc(item)) {
            result.Push(item)
        }
    }
    return result
}

; Map array to new values
ArrayMap(arr, transformFunc) {
    result := []
    for item in arr {
        result.Push(transformFunc(item))
    }
    return result
}