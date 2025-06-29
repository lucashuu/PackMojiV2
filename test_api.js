const axios = require('axios');

async function testAPI() {
    try {
        console.log('Testing PackMoji API...\n');
        
        const response = await axios.post('http://localhost:3000/api/v1/generate-checklist', {
            destination: 'Paris',
            startDate: '2024-12-25',
            endDate: '2024-12-30',
            activities: ['activity_city', 'activity_shopping'],
            originCountry: 'US'
        }, {
            headers: {
                'Content-Type': 'application/json',
                'Accept-Language': 'en'
            }
        });

        console.log('✅ API Response received successfully!');
        console.log('\n📋 Checklist Categories:');
        
        response.data.checklist.forEach((category, index) => {
            console.log(`\n${index + 1}. ${category.category}:`);
            category.items.forEach(item => {
                const urlInfo = item.url ? ` (🔗 ${item.url})` : '';
                console.log(`   - ${item.emoji} ${item.name} x${item.quantity}${urlInfo}`);
            });
        });
        
        console.log('\n🌍 Trip Info:');
        console.log(`   Destination: ${response.data.tripInfo.destinationName}`);
        console.log(`   Duration: ${response.data.tripInfo.durationDays} days`);
        console.log(`   Weather: ${response.data.tripInfo.weatherSummary}`);
        
        // Check for URL items
        const urlItems = response.data.checklist.flatMap(cat => cat.items).filter(item => item.url);
        if (urlItems.length > 0) {
            console.log('\n🔗 Items with URLs:');
            urlItems.forEach(item => {
                console.log(`   - ${item.name}: ${item.url}`);
            });
        }
        
        console.log('\n✅ Test completed successfully!');
        
    } catch (error) {
        console.error('❌ Error:', error.response ? error.response.data : error.message);
        
        if (error.code === 'ECONNREFUSED') {
            console.log('\n💡 Make sure the backend server is running:');
            console.log('   cd backend && npm start');
        }
    }
}

testAPI(); 