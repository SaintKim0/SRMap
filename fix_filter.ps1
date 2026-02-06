$content = Get-Content -Path "lib\presentation\providers\location_provider.dart" -Encoding UTF8 -Raw

# Replace the filtering logic for Black & White Chef
$oldPattern = @"
      } else if \(sector == '흑백요리사'\) \{
        // Filter by Black & White Chef - check category or description
        _sectorLocations = allLocs\.where\(\(loc\) \{
          final category = loc\.category\.toLowerCase\(\);
          final description = \(loc\.description \?\? ''\)\.toLowerCase\(\);
          final contentTitle = \(loc\.contentTitle \?\? ''\)\.toLowerCase\(\);
          
          if \(subSector == '흑백요리사 시즌1'\) \{
            return category\.contains\('흑백'\) \|\| 
                   description\.contains\('흑백'\) \|\| 
                   contentTitle\.contains\('흑백'\) \|\|
                   description\.contains\('시즌1'\) \|\|
                   description\.contains\('season 1'\);
          \} else if \(subSector == '흑백요리사 시즌2'\) \{
            return category\.contains\('흑백'\) \|\| 
                   description\.contains\('흑백'\) \|\| 
                   contentTitle\.contains\('흑백'\) \|\|
                   description\.contains\('시즌2'\) \|\|
                   description\.contains\('season 2'\);
          \} else \{
            return category\.contains\('흑백'\) \|\| 
                   description\.contains\('흑백'\) \|\| 
                   contentTitle\.contains\('흑백'\);
          \}
        \}\)\.toList\(\);
"@

$newContent = @"
      } else if (sector == '흑백요리사') {
        // Filter by Black & White Chef - check exact contentTitle match
        _sectorLocations = allLocs.where((loc) {
          final contentTitle = (loc.contentTitle ?? '').trim();
          
          if (subSector == '흑백요리사 시즌1') {
            return contentTitle == '흑백요리사 시즌1' || 
                   contentTitle == '흑백요리사';
          } else if (subSector == '흑백요리사 시즌2') {
            return contentTitle == '흑백요리사 시즌2';
          } else {
            // Show all Black & White Chef locations
            return contentTitle.startsWith('흑백요리사');
          }
        }).toList();
"@

$content = $content -replace $oldPattern, $newContent

Set-Content -Path "lib\presentation\providers\location_provider.dart" -Value $content -Encoding UTF8
Write-Host "File updated successfully"
