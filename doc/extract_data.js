// 다이닝코드 페이지에서 브라우저 개발자 도구 Console에서 실행할 코드
// F12를 눌러 개발자 도구를 열고 Console 탭에서 이 코드를 붙여넣고 실행하세요

(function() {
    console.log('='.repeat(60));
    console.log('다이닝코드 데이터 추출 시작...');
    console.log('='.repeat(60));
    
    // localStorage에서 데이터 가져오기
    let listDataStr = localStorage.getItem('listData');
    
    if (!listDataStr) {
        console.error('❌ listData를 찾을 수 없습니다. 페이지를 새로고침해주세요.');
        return;
    }
    
    let data = JSON.parse(listDataStr);
    
    if (!data.poi_section || !data.poi_section.list) {
        console.error('❌ 식당 데이터를 찾을 수 없습니다.');
        return;
    }
    
    let restaurants = data.poi_section.list;
    console.log(`\n📊 총 ${restaurants.length}개 식당 데이터 발견!`);
    
    // CSV 헤더는 없음 (기존 파일 형식에 맞춤)
    let csv = '';
    let currentDate = new Date().toISOString().split('T')[0];
    
    // 중복 제거를 위한 Set
    let seen = new Set();
    let uniqueRestaurants = [];
    
    restaurants.forEach(r => {
        let name = r.nm + (r.branch ? ' ' + r.branch : '');
        let address = r.road_addr || r.addr;
        let key = name + '|' + address;
        
        if (!seen.has(key)) {
            seen.add(key);
            uniqueRestaurants.push(r);
            
            // CSV 행 생성 (black_white_season1.csv 형식)
            csv += `"0","show","맛있는녀석들","${name}","restaurant","","","","","${address}","${r.lat}","${r.lng}","","${currentDate}"\n`;
        }
    });
    
    console.log(`✅ 중복 제거 후: ${uniqueRestaurants.length}개 고유 식당`);
    
    // 클립보드에 복사
    navigator.clipboard.writeText(csv).then(() => {
        console.log('\n✅ CSV 데이터가 클립보드에 복사되었습니다!');
        console.log('\n📋 다음 단계:');
        console.log('1. 메모장이나 텍스트 에디터를 엽니다');
        console.log('2. Ctrl+V로 붙여넣기 합니다');
        console.log('3. tasty_boys.csv 파일로 저장합니다');
        console.log(`\n파일 위치: d:\\00_projects\\02_TasteMap\\doc\\tasty_boys.csv`);
        
        // 샘플 데이터 출력
        console.log('\n🍽️  샘플 데이터 (처음 5개):');
        uniqueRestaurants.slice(0, 5).forEach((r, i) => {
            let name = r.nm + (r.branch ? ' ' + r.branch : '');
            console.log(`${i + 1}. ${name} (${r.area ? r.area.join(', ') : ''})`);
            console.log(`   주소: ${r.road_addr || r.addr}`);
            console.log(`   평점: ${r.user_score} (리뷰 ${r.review_cnt}개)`);
        });
        
        // 지역별 통계
        let areas = {};
        uniqueRestaurants.forEach(r => {
            if (r.area && r.area.length > 0) {
                r.area.forEach(a => {
                    areas[a] = (areas[a] || 0) + 1;
                });
            }
        });
        
        console.log('\n📍 지역별 분포:');
        Object.entries(areas)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 10)
            .forEach(([area, count]) => {
                console.log(`  - ${area}: ${count}개`);
            });
        
    }).catch(err => {
        console.error('❌ 클립보드 복사 실패:', err);
        console.log('\n💡 수동으로 복사하세요:');
        console.log('아래 데이터를 선택하여 복사하세요:');
        console.log('='.repeat(60));
        console.log(csv);
        console.log('='.repeat(60));
    });
    
})();
