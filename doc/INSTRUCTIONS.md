# 브라우저 콘솔에서 실행할 새로운 명령어

## 방법 1: 페이지의 script 태그에서 데이터 추출

```javascript
// 페이지의 모든 script 태그를 검색하여 listData 찾기
let scripts = document.getElementsByTagName('script');
let listData = null;

for (let script of scripts) {
    if (script.textContent.includes('localStorage.setItem')) {
        let match = script.textContent.match(/localStorage\.setItem\('listData',\s*'(.+?)'\);/s);
        if (match) {
            try {
                let jsonStr = match[1].replace(/\\\\/g, '\\').replace(/\\'/g, "'");
                listData = JSON.parse(jsonStr);
                break;
            } catch(e) {
                console.log('파싱 오류:', e);
            }
        }
    }
}

if (listData && listData.poi_section && listData.poi_section.list) {
    copy(JSON.stringify(listData.poi_section.list));
    console.log(`✅ ${listData.poi_section.list.length}개 식당 데이터가 클립보드에 복사되었습니다!`);
} else {
    console.log('❌ 데이터를 찾을 수 없습니다.');
}
```

## 방법 2: 더 간단한 방법 - 화면에 보이는 식당 카드에서 직접 추출

```javascript
// 페이지에 표시된 식당 카드들에서 데이터 추출
let restaurants = [];
let cards = document.querySelectorAll('.PoiBlock, .poi-item, [class*="restaurant"], [class*="poi"]');

console.log(`발견된 카드: ${cards.length}개`);

// 만약 카드가 없다면 다른 선택자 시도
if (cards.length === 0) {
    // 페이지 구조 확인
    console.log('페이지 구조를 확인합니다...');
    console.log(document.body.innerHTML.substring(0, 1000));
}
```

---

## 💡 가장 쉬운 방법: 수동으로 JSON 복사

1. 개발자 도구(F12)에서 **Network** 탭을 엽니다
2. 페이지를 새로고침합니다 (F5)
3. Network 탭에서 `list.dc` 또는 API 요청을 찾습니다
4. Response 탭에서 JSON 데이터를 복사합니다

또는 제가 다른 방법으로 시도해볼까요?
