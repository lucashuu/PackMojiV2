const recommendationService = require('./backend/services/recommendation.service.js');

// 测试国际旅行场景
const internationalTripContext = {
    durationDays: 7,
    avgTemp: 20,
    weatherCode: 'clear',
    activities: ['activity_city'],
    lang: 'zh',
    tripType: 'international',
    originCountry: 'CN',
    destination: 'Tokyo, Japan'
};

console.log('🔍 测试国际旅行推荐：');
console.log('Trip Type:', internationalTripContext.tripType);
console.log('Destination:', internationalTripContext.destination);
console.log('---');

const internationalRecommendations = recommendationService.getRecommendedItems(internationalTripContext);

console.log('\n📋 国际旅行推荐结果（前30项）：');
internationalRecommendations.slice(0, 30).forEach((item, index) => {
    console.log(`${index + 1}. ${item.emoji} ${item.name} (${item.id}) - 分数: ${item.score.toFixed(1)}`);
});

// 测试国内旅行场景
const domesticTripContext = {
    durationDays: 3,
    avgTemp: 15,
    weatherCode: 'clouds',
    activities: ['activity_city'],
    lang: 'zh',
    tripType: 'domestic',
    originCountry: 'CN',
    destination: 'Beijing, China'
};

console.log('\n\n🔍 测试国内旅行推荐：');
console.log('Trip Type:', domesticTripContext.tripType);
console.log('Destination:', domesticTripContext.destination);
console.log('---');

const domesticRecommendations = recommendationService.getRecommendedItems(domesticTripContext);

console.log('\n📋 国内旅行推荐结果（前30项）：');
domesticRecommendations.slice(0, 30).forEach((item, index) => {
    console.log(`${index + 1}. ${item.emoji} ${item.name} (${item.id}) - 分数: ${item.score.toFixed(1)}`);
}); 