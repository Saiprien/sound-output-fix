$script:deviceConfig = @{
    Speakers = @{nameMode='Speakers'; customName=''; endpointId=''; image=''}
    EarPods = @{nameMode='EarPods'; customName=''; endpointId=''; image=''}
}
try {
    $configPath = Join-Path $root 'settings.json'
    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        foreach ($slot in @('Speakers','EarPods')) {
            foreach ($field in @('nameMode','customName','endpointId','image')) {
                $value = $config.devices.$slot.$field
                if ($null -ne $value) { $script:deviceConfig[$slot][$field] = [string]$value }
            }
        }
    }
} catch { }
function Get-DeviceName([string]$slot) {
    $config = $script:deviceConfig[$slot]
    if ($config.nameMode -eq 'Custom' -and $config.customName.Trim()) { return $config.customName.Trim() }
    if ($config.nameMode -eq 'Speakers') {
        if (Get-Command T -ErrorAction SilentlyContinue) { return (T 'SpeakersNormal') }
        return 'Speakers'
    }
    if ($config.nameMode -eq 'Headphones' -and (Get-Command T -ErrorAction SilentlyContinue)) { return (T 'HeadphonesNormal') }
    return $config.nameMode
}
function Get-DefaultDeviceImage([string]$slot) {
    $kind = if ($slot -eq 'Speakers') { 'speakers' } else { 'headphones' }
    $theme = if ($script:resolvedTheme -eq 'light') { 'light' } else { 'dark' }
    return (Join-Path $root ('assets\' + $kind + '-' + $theme + '.png'))
}
function Get-DeviceImage([string]$slot) {
    $relative = $script:deviceConfig[$slot].image
    if ($relative -and (Test-Path -LiteralPath (Join-Path $root $relative))) { return (Join-Path $root $relative) }
    return Get-DefaultDeviceImage $slot
}
function Get-RenderEndpoints {
    @(Get-ChildItem $audioRoot | ForEach-Object {
        $props = Get-ItemProperty ($_.PSPath + '\Properties')
        $label = $props.'{a45c254e-df1c-4efd-8020-67d146a850e0},2'
        $driver = $props.'{b3f8fa53-0004-438e-9003-51a46e139bfc},6'
        [pscustomobject]@{Key=$_.PSPath; Id=('{0.0.0.00000000}.' + $_.PSChildName); FriendlyId=($driver+'\Device\'+$label+'\Render'); Name=($label+' ('+$driver+')'); State=[int](Get-ItemProperty $_.PSPath).DeviceState}
    })
}
function Get-ConfiguredEndpoint([string]$slot) {
    $id = $script:deviceConfig[$slot].endpointId
    if ($id) { return (Get-RenderEndpoints | Where-Object Id -eq $id | Select-Object -First 1) }
    if ($slot -eq 'Speakers') { return Find-Endpoint 'Speakers' 'Realtek(R) Audio' }
    return Find-Endpoint 'Headset' 'EarPods'
}
