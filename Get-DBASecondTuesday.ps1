function SecondTuesday ([int]$Month, [int]$Year) {
    [int]$Day = 1
    while((Get-Date -Day $Day -Hour 0 -Millisecond 0 -Minute 0 -Month $Month -Year $Year -Second 0).DayOfWeek -ne "Tuesday") {
        $day++
    }
    $day += 7
    return (Get-Date -Day $Day -Hour 0 -Millisecond 0 -Minute 0 -Month $Month -Year $Year -Second 0)
}

function ThirdTuesday ([int]$Month, [int]$Year) {
    [int]$Day = 1
    while((Get-Date -Day $Day -Hour 0 -Millisecond 0 -Minute 0 -Month $Month -Year $Year -Second 0).DayOfWeek -ne "Tuesday") {
        $day++
    }
    $day += 14
    return (Get-Date -Day $Day -Hour 0 -Millisecond 0 -Minute 0 -Month $Month -Year $Year -Second 0)
}

1..12 | foreach {(ThirdTuesday $_ 2017).AddDays(2).ToString('yyyy/MM/dd')}
