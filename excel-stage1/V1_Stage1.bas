Attribute VB_Name = "modSocietyStage1"
Option Explicit

' Stage 1 helper macros. Test ONLY on a copy with fictional data.

Public Sub AddNewMember()
    Dim ws As Worksheet, nextRow As Long, memberID As String, memberName As String
    Set ws = ThisWorkbook.Worksheets("Members")
    memberID = Trim(InputBox("Enter unique Member ID:"))
    If memberID = "" Then Exit Sub
    If Application.WorksheetFunction.CountIf(ws.Range("A5:A5000"), memberID) > 0 Then
        MsgBox "Member ID already exists.", vbExclamation: Exit Sub
    End If
    memberName = Trim(InputBox("Enter member full name:"))
    If memberName = "" Then Exit Sub
    nextRow = ws.Cells(ws.Rows.Count, "A").End(xlUp).Row + 1
    If nextRow < 5 Then nextRow = 5
    ws.Cells(nextRow, "A").Value = memberID
    ws.Cells(nextRow, "B").Value = memberName
    ws.Cells(nextRow, "D").Value = Date
    ws.Cells(nextRow, "H").Value = "Active"
    MsgBox "Member added. Complete remaining details in Members sheet.", vbInformation
End Sub

Public Sub FindMember()
    Dim memberID As String, ws As Worksheet, hit As Range
    memberID = Trim(InputBox("Enter Member ID:"))
    If memberID = "" Then Exit Sub
    Set ws = ThisWorkbook.Worksheets("Members")
    Set hit = ws.Range("A5:A5000").Find(What:=memberID, LookIn:=xlValues, LookAt:=xlWhole)
    If hit Is Nothing Then
        MsgBox "Member not found.", vbExclamation
    Else
        ws.Activate: hit.Select
        MsgBox "Found: " & ws.Cells(hit.Row, "B").Value, vbInformation
    End If
End Sub

Public Sub ValidateRecoveryEntry()
    Dim ws As Worksheet, r As Long, total As Double, memberID As String
    Set ws = ThisWorkbook.Worksheets("Recovery Entry")
    r = ActiveCell.Row
    If r < 5 Then MsgBox "Select a recovery row (row 5 or below).": Exit Sub
    memberID = Trim(CStr(ws.Cells(r, "C").Value))
    If memberID = "" Then MsgBox "Member ID is required.", vbExclamation: Exit Sub
    If Application.WorksheetFunction.CountIf(ThisWorkbook.Worksheets("Members").Range("A5:A5000"), memberID) = 0 Then
        MsgBox "Member ID not found in Members Master.", vbCritical: Exit Sub
    End If
    total = Application.WorksheetFunction.Sum(ws.Range("D" & r & ":K" & r))
    ws.Cells(r, "L").Value = total
    If total <= 0 Then MsgBox "Recovery total must be greater than zero.", vbExclamation: Exit Sub
    MsgBox "Recovery row validated. No accounting entries have been posted.", vbInformation
End Sub

Public Sub CheckJournalBalance()
    Dim ws As Worksheet, lastRow As Long, debits As Double, credits As Double
    Set ws = ThisWorkbook.Worksheets("Journal")
    lastRow = ws.Cells(ws.Rows.Count, "A").End(xlUp).Row
    If lastRow < 5 Then MsgBox "No journal entries found.": Exit Sub
    debits = Application.WorksheetFunction.Sum(ws.Range("G5:G" & lastRow))
    credits = Application.WorksheetFunction.Sum(ws.Range("H5:H" & lastRow))
    If Abs(debits - credits) < 0.01 Then
        MsgBox "Journal balances. Debit = " & Format(debits, "#,##0.00"), vbInformation
    Else
        MsgBox "Journal does not balance. Difference = " & Format(debits - credits, "#,##0.00"), vbCritical
    End If
End Sub