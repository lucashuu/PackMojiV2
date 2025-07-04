const recommendationService = require('./backend/services/recommendation.service');

// Test the recommendation logic directly
function testRecommendation() {
    console.log('🧪 Testing Recommendation Logic...\n');
    
    const testCases = [
        {
            name: "International Trip with City Activities",
            context: {
                durationDays: 5,
                avgTemp: 20,
                weatherCode: "clear",
                activities: ["activity_city", "activity_shopping"],
                lang: "en",
                tripType: "international",
                originCountry: "US",
                destination: "Paris"
            }
        },
        {
            name: "Beach Vacation Trip",
            context: {
                durationDays: 7,
                avgTemp: 28,
                weatherCode: "clear",
                activities: ["activity_beach"],
                lang: "en",
                tripType: "international",
                originCountry: "US",
                destination: "Maldives"
            }
        }
    ];
    
    testCases.forEach((testCase, index) => {
        console.log(`\n📋 Test Case ${index + 1}: ${testCase.name}`);
        console.log('=' .repeat(50));
        
        try {
            const items = recommendationService.getRecommendedItems(testCase.context);
            
            console.log(`✅ Found ${items.length} recommended items:`);
            
            // Group by category
            const byCategory = {};
            items.forEach(item => {
                if (!byCategory[item.category]) {
                    byCategory[item.category] = [];
                }
                byCategory[item.category].push(item);
            });
            
            Object.keys(byCategory).forEach(category => {
                console.log(`\n  📁 ${category}:`);
                byCategory[category].forEach(item => {
                    const urlInfo = item.url ? ` (🔗 ${item.url})` : '';
                    console.log(`    - ${item.emoji} ${item.name} x${item.quantity}${urlInfo}`);
                });
            });
            
        } catch (error) {
            console.error(`❌ Error in test case ${index + 1}:`, error.message);
        }
    });
}

testRecommendation(); 