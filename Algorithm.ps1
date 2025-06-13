Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Function to enable double buffering via reflection1
function Enable-DoubleBuffering($control) {
    $type = $control.GetType()
    $prop = $type.GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)
    $prop.SetValue($control, $true, $null)
}

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Sorting Algorithm Visualizer"
$form.Size = New-Object System.Drawing.Size(800,600)
$form.StartPosition = "CenterScreen"
Enable-DoubleBuffering $form

# Create controls
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(10,10)
$comboBox.Size = New-Object System.Drawing.Size(150,20)
$comboBox.Items.AddRange(@("Bubble Sort", "Selection Sort", "Merge Sort", "Quick Sort", "Heap Sort", "Radix Sort"))

$sortButton = New-Object System.Windows.Forms.Button
$sortButton.Location = New-Object System.Drawing.Point(170,10)
$sortButton.Size = New-Object System.Drawing.Size(100,23)
$sortButton.Text = "Sort"

$randomButton = New-Object System.Windows.Forms.Button
$randomButton.Location = New-Object System.Drawing.Point(280,10)
$randomButton.Size = New-Object System.Drawing.Size(100,23)
$randomButton.Text = "Randomize"

$lengthLabel = New-Object System.Windows.Forms.Label
$lengthLabel.Location = New-Object System.Drawing.Point(390,12)
$lengthLabel.Size = New-Object System.Drawing.Size(60,20)
$lengthLabel.Text = "Length:"

$lengthUpDown = New-Object System.Windows.Forms.NumericUpDown
$lengthUpDown.Location = New-Object System.Drawing.Point(450,10)
$lengthUpDown.Size = New-Object System.Drawing.Size(50,20)
$lengthUpDown.Minimum = 20
$lengthUpDown.Maximum = 40
$lengthUpDown.Value = 20

$timeLabel = New-Object System.Windows.Forms.Label
$timeLabel.Location = New-Object System.Drawing.Point(510,12)
$timeLabel.Size = New-Object System.Drawing.Size(200,20)
$timeLabel.Text = "Time: 0 ms"

$stabilityLabel = New-Object System.Windows.Forms.Label
$stabilityLabel.Location = New-Object System.Drawing.Point(10,35)
$stabilityLabel.Size = New-Object System.Drawing.Size(150,20)
$stabilityLabel.Text = "Stability: N/A"

$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(10,60)
$panel.Size = New-Object System.Drawing.Size(760,480)
$panel.BorderStyle = "FixedSingle"
Enable-DoubleBuffering $panel

# Global variables for sorting visualization
$script:activeIndices = @()
$script:updateCounter = 0
$script:updateFrequency = 1

# Function to update stability label
function Update-StabilityLabel($algorithm) {
    switch ($algorithm) {
        "Bubble Sort" { $stabilityLabel.Text = "Stability: Stable" }
        "Selection Sort" { $stabilityLabel.Text = "Stability: Unstable" }
        "Merge Sort" { $stabilityLabel.Text = "Stability: Stable" }
        "Quick Sort" { $stabilityLabel.Text = "Stability: Unstable" }
        "Heap Sort" { $stabilityLabel.Text = "Stability: Unstable" }
        "Radix Sort" { $stabilityLabel.Text = "Stability: Stable" }
        default { $stabilityLabel.Text = "Stability: N/A" }
    }
}

# Sorting algorithms implementation (working with value-index pairs)
function Bubble-Sort($arr) {
    $n = $arr.Length
    for ($i = 0; $i -lt $n - 1; $i++) {
        for ($j = 0; $j -lt $n - $i - 1; $j++) {
            if ($arr[$j].Value -gt $arr[$j + 1].Value) {
                $script:activeIndices = @($j, $($j + 1))
                $temp = $arr[$j]
                $arr[$j] = $arr[$j + 1]
                $arr[$j + 1] = $temp
                Update-Display $arr
            }
        }
    }
    $script:activeIndices = @()
    Update-Display $arr -Force
}

function Selection-Sort($arr) {
    $n = $arr.Length
    for ($i = 0; $i -lt $n - 1; $i++) {
        $minIdx = $i
        for ($j = $i + 1; $j -lt $n; $j++) {
            if ($arr[$j].Value -lt $arr[$minIdx].Value) {
                $minIdx = $j
            }
        }
        $script:activeIndices = @($i, $minIdx)
        $temp = $arr[$minIdx]
        $arr[$minIdx] = $arr[$i]
        $arr[$i] = $temp
        Update-Display $arr
    }
    $script:activeIndices = @()
    Update-Display $arr -Force
}

function Merge-Sort($arr, $start = 0, $end = $arr.Length - 1) {
    if ($start -lt $end) {
        $mid = [math]::Floor(($start + $end) / 2)
        Merge-Sort $arr $start $mid
        Merge-Sort $arr ($mid + 1) $end
        Merge $arr $start $mid $end
    }
    if ($start -eq 0 -and $end -eq $arr.Length - 1) {
        $script:activeIndices = @()
        Update-Display $arr -Force
    }
}

function Merge($arr, $start, $mid, $end) {
    $left = $arr[$start..$mid]
    $right = $arr[($mid + 1)..$end]
    $i = $j = 0
    $k = $start
    
    while ($i -lt $left.Length -and $j -lt $right.Length) {
        $script:activeIndices = @($k)
        if ($left[$i].Value -le $right[$j].Value) {
            $arr[$k] = $left[$i]
            $i++
        } else {
            $arr[$k] = $right[$j]
            $j++
        }
        $k++
        Update-Display $arr
    }
    
    while ($i -lt $left.Length) {
        $script:activeIndices = @($k)
        $arr[$k] = $left[$i]
        $i++
        $k++
        Update-Display $arr
    }
    
    while ($j -lt $right.Length) {
        $script:activeIndices = @($k)
        $arr[$k] = $right[$j]
        $j++
        $k++
        Update-Display $arr
    }
}

function Quick-Sort($arr, $low = 0, $high = $arr.Length - 1) {
    if ($low -lt $high) {
        $pi = Partition $arr $low $high
        Quick-Sort $arr $low ($pi - 1)
        Quick-Sort $arr ($pi + 1) $high
        Update-Display $arr
    }
    if ($low -eq 0 -and $high -eq $arr.Length - 1) {
        $script:activeIndices = @()
        Update-Display $arr -Force
    }
    return $arr
}

function Partition($arr, $low, $high) {
    $pivot = $arr[$high].Value
    $i = $low - 1
    
    for ($j = $low; $j -lt $high; $j++) {
        if ($arr[$j].Value -le $pivot) {
            $i++
            $script:activeIndices = @($i, $j)
            $temp = $arr[$i]
            $arr[$i] = $arr[$j]
            $arr[$j] = $temp
            Update-Display $arr
        }
    }
    
    $script:activeIndices = @($($i + 1), $high)
    $temp = $arr[$i + 1]
    $arr[$i + 1] = $arr[$high]
    $arr[$high] = $temp
    Update-Display $arr
    return $i + 1
}

function Heap-Sort($arr) {
    $n = $arr.Length
    
    for ($i = [math]::Floor($n / 2) - 1; $i -ge 0; $i--) {
        Heapify $arr $n $i
    }
    
    for ($i = $n - 1; $i -gt 0; $i--) {
        $script:activeIndices = @(0, $i)
        $temp = $arr[0]
        $arr[0] = $arr[$i]
        $arr[$i] = $temp
        Update-Display $arr
        Heapify $arr $i 0
    }
    $script:activeIndices = @()
    Update-Display $arr -Force
}

function Heapify($arr, $n, $i) {
    $largest = $i
    $left = 2 * $i + 1
    $right = 2 * $i + 2
    
    if ($left -lt $n -and $arr[$left].Value -gt $arr[$largest].Value) {
        $largest = $left
    }
    
    if ($right -lt $n -and $arr[$right].Value -gt $arr[$largest].Value) {
        $largest = $right
    }
    
    if ($largest -ne $i) {
        $script:activeIndices = @($i, $largest)
        $temp = $arr[$i]
        $arr[$i] = $arr[$largest]
        $arr[$largest] = $temp
        Update-Display $arr
        Heapify $arr $n $largest
    }
}

function Radix-Sort($arr) {
    $max = ($arr | ForEach-Object { $_.Value } | Measure-Object -Maximum).Maximum
    
    for ($exp = 1; [math]::Floor($max/$exp) -gt 0; $exp *= 10) {
        Counting-Sort $arr $exp
        Update-Display $arr
    }
    $script:activeIndices = @()
    Update-Display $arr -Force
}

function Counting-Sort($arr, $exp) {
    $n = $arr.Length
    $output = New-Object object[] $n
    $count = New-Object int[] 10
    
    for ($i = 0; $i -lt $n; $i++) {
        $count[([math]::Floor($arr[$i].Value/$exp) % 10)]++
    }
    
    for ($i = 1; $i -lt 10; $i++) {
        $count[$i] += $count[$i - 1]
    }
    
    for ($i = $n - 1; $i -ge 0; $i--) {
        $index = [math]::Floor($arr[$i].Value/$exp) % 10
        $script:activeIndices = @($i, $count[$index] - 1)
        $output[$count[$index] - 1] = $arr[$i]
        $count[$index]--
        Update-Display $arr
    }
    
    for ($i = 0; $i -lt $n; $i++) {
        $arr[$i] = $output[$i]
    }
}

# Optimized display update function with original index labels
function Update-Display($arr, [switch]$Force) {
    $script:updateCounter++
    
    if ($Force -or ($script:updateCounter -ge $script:updateFrequency)) {
        $panel.Controls.Clear()
        $barWidth = [math]::Floor($panel.Width / $arr.Length)
        $maxHeight = $panel.Height
        $maxValue = ($arr | ForEach-Object { $_.Value } | Measure-Object -Maximum).Maximum
        
        for ($i = 0; $i -lt $arr.Length; $i++) {
            $barHeight = [math]::Floor(($arr[$i].Value / $maxValue) * $maxHeight)
            $bar = New-Object System.Windows.Forms.Panel
            $bar.Size = New-Object System.Drawing.Size($barWidth, $barHeight)
            $bar.Location = New-Object System.Drawing.Point(($i * $barWidth), ($maxHeight - $barHeight))
            if ($script:activeIndices -contains $i) {
                $bar.BackColor = [System.Drawing.Color]::Red
            } else {
                $bar.BackColor = [System.Drawing.Color]::Gray
            }
            
            # Add label showing original index
            $label = New-Object System.Windows.Forms.Label
            $label.Text = $arr[$i].OriginalIndex.ToString()
            $label.AutoSize = $true
            $label.ForeColor = [System.Drawing.Color]::Black
            $label.Location = New-Object System.Drawing.Point(
                [math]::Max(0, ($barWidth - $label.PreferredWidth) / 2),
                [math]::Max(0, $barHeight - 20)
            )
            $bar.Controls.Add($label)
            $panel.Controls.Add($bar)
        }
        $panel.Invalidate()
        $script:updateCounter = 0
        
        # Uniform sleep for all algorithms
        Start-Sleep -Milliseconds 50
    }
}

# Generate initial random array with duplicates and original indices
$data = @()
for ($i = 0; $i -lt $lengthUpDown.Value; $i++) {
    $data += [PSCustomObject]@{
        Value = Get-Random -Minimum 1 -Maximum 10
        OriginalIndex = $i
    }
}
Update-Display $data -Force

# Sort button click event with timing and stability update
$sortButton.Add_Click({
    $selectedSort = $comboBox.SelectedItem
    if ($selectedSort) {
        Update-StabilityLabel $selectedSort
        $script:dataCopy = $data | ForEach-Object { [PSCustomObject]@{ Value = $_.Value; OriginalIndex = $_.OriginalIndex } }
        $script:updateCounter = 0
        $script:activeIndices = @()
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        switch ($selectedSort) {
            "Bubble Sort" { Bubble-Sort $dataCopy }
            "Selection Sort" { Selection-Sort $dataCopy }
            "Merge Sort" { Merge-Sort $dataCopy 0 ($dataCopy.Length - 1) }
            "Quick Sort" { $script:dataCopy = Quick-Sort $dataCopy }
            "Heap Sort" { Heap-Sort $dataCopy }
            "Radix Sort" { Radix-Sort $dataCopy }
        }
        
        $stopwatch.Stop()
        $timeLabel.Text = "Time: $($stopwatch.ElapsedMilliseconds) ms"
        $script:data = $dataCopy
    }
})

# Randomize button click event
$randomButton.Add_Click({
    $script:data = @()
    for ($i = 0; $i -lt $lengthUpDown.Value; $i++) {
        $script:data += [PSCustomObject]@{
            Value = Get-Random -Minimum 1 -Maximum 10
            OriginalIndex = $i
        }
    }
    $script:activeIndices = @()
    Update-Display $data -Force
    $timeLabel.Text = "Time: 0 ms"
    Update-StabilityLabel $comboBox.SelectedItem
})

# ComboBox selection change event to update stability
$comboBox.Add_SelectedIndexChanged({
    Update-StabilityLabel $comboBox.SelectedItem
})

# Add controls to form
$form.Controls.Add($comboBox)
$form.Controls.Add($sortButton)
$form.Controls.Add($randomButton)
$form.Controls.Add($lengthLabel)
$form.Controls.Add($lengthUpDown)
$form.Controls.Add($timeLabel)
$form.Controls.Add($stabilityLabel)
$form.Controls.Add($panel)

# Show form
$form.ShowDialog()