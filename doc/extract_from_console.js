// 브라우저 개발자 도구 콘솔(F12)에서 실행하세요
// 현재 로드된 모든 식당 데이터를 추출합니다

// localStorage에서 데이터 가져오기
const listData = JSON.parse(localStorage.getItem('listData'));

if (listData && listData.poi_section && listData.poi_section.list) {
    const restaurants = listData.poi_section.list;

    console.log(`총 ${restaurants.length}개의 식당 데이터 발견`);

    // CSV 형식으로 변환
    const csvRows = [];
    csvRows.push('id,sector,title,name,type,chef,address,lat,lng,date,area,user_score,review_cnt');

    const today = new Date().toISOString().split('T')[0];

    restaurants.forEach((rest, idx) => {
        const name = rest.branch ? `${rest.nm} ${rest.branch}` : rest.nm;
        const address = rest.road_addr || rest.addr || '';
        const category = rest.category || '';
        const lat = rest.lat || '';
        const lng = rest.lng || '';
        const area = rest.area && rest.area[0] ? rest.area[0] : '';
        const userScore = rest.user_score || '';
        const reviewCnt = rest.review_cnt || '';

        // CSV 행 생성 (쉼표가 포함된 필드는 따옴표로 감싸기)
        const row = [
            idx + 1,
            '맛있는녀석들',
            '맛있는녀석들',
            `"${name.replace(/"/g, '""')}"`,
            `"${category.replace(/"/g, '""')}"`,
            '',
            `"${address.replace(/"/g, '""')}"`,
            lat,
            lng,
            today,
            area,
            userScore,
            reviewCnt
        ].join(',');

        csvRows.push(row);
    });

    const csvContent = csvRows.join('\n');

    // 클립보드에 복사
    navigator.clipboard.writeText(csvContent).then(() => {
        console.log('✅ CSV 데이터가 클립보드에 복사되었습니다!');
        console.log(`총 ${restaurants.length}개의 식당 데이터`);
        console.log('\n다음 단계:');
        console.log('1. 메모장을 열고 Ctrl+V로 붙여넣기');
        console.log('2. tasty_boys.csv 파일로 저장');
    }).catch(err => {
        console.error('클립보드 복사 실패:', err);
        console.log('\n대신 아래 데이터를 수동으로 복사하세요:');
        console.log(csvContent);
    });

} else {
    console.error('❌ localStorage에서 listData를 찾을 수 없습니다');
}
