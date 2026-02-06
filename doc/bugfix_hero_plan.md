# Bug Fix: Duplicate Hero Tags & API Image Check

## 1. Issue Description
- **Crash**: `There are multiple heroes that share the same tag within a subtree`.
- **Cause**: The same `Location` appears in both "Popular" and "Recent" lists on `HomeScreen`. Since `LocationCard` uses `location.id` as the Hero tag, Flutter sees duplicates.
- **User Question**: "How are images created?" (Currently placeholders).

## 2. Proposed Changes
### 2.1 Hero Tag Fix
- **Modify `LocationCard`**:
    - Add `final String? heroTagPrefix`.
    - `heroTag` = `heroTagPrefix != null ? '${heroTagPrefix}_${location.id}' : location.id`.
- **Update `HomeScreen`**:
    - Pass `heroTagPrefix: 'popular'` for Popular list.
    - Pass `heroTagPrefix: 'recent'` for Recent list.
- **Update `LocationDetailScreen`**:
    - Add `final String? heroTag` to constructor.
    - Use this tag for the Hero widget.
- **Update Navigation**:
    - Pass the constructed tag when pushing `LocationDetailScreen`.

### 2.2 Image Handling
- The API check returned 403 (Forbidden), so we can't confirm image fields yet.
- **Strategy**: Keep using placeholders (`picsum.photos`) for now.
- **Long-term**: Suggest "Naver Image Search API" or manual Admin upload to the user.

## 3. Verification
- **Manual Test**: Run app, see if crash is gone when both lists load.
- **Animation Check**: Click card in Recent list -> Verify Hero transition works. Click card in Popular list -> Verify Hero transition works.
