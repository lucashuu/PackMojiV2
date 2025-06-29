const items = require('../items.json');

// A mapping from OpenWeatherMap main condition codes to our internal categories
const weatherConditionMap = {
    'thunderstorm': 'rainy',
    'drizzle': 'rainy',
    'rain': 'rainy',
    'snow': 'snowy',
    'clear': 'sunny',
    'clouds': 'clouds',
    // Atmosphere group - map to a general "special" category or handle as needed
    'mist': 'special',
    'smoke': 'special',
    'haze': 'special',
    'dust': 'special',
    'fog': 'special',
    'sand': 'special',
    'ash': 'special',
    'squall': 'special',
    'tornado': 'special',
};

/**
 * Calculates a match score for an item based on the trip context.
 * @param {object} item - The item from the database.
 * @param {object} tripContext - The context of the trip (weather, activities, etc.).
 * @returns {number} - A score between 0 and 1.
 */
function calculateMatchScore(item, tripContext) {
    let score = 0;
    const WEIGHTS = { temp: 0.5, weather: 0.3, activity: 0.2 };

    // 1. Temperature scoring
    const { temp_min, temp_max } = item.attributes;
    if (tripContext.avgTemp >= temp_min && tripContext.avgTemp <= temp_max) {
        score += WEIGHTS.temp;
    }

    // 2. Weather condition scoring
    const itemWeatherConditions = item.attributes.weather_condition;
    const tripWeatherCategory = weatherConditionMap[tripContext.weatherCode] || 'any';
    
    if (itemWeatherConditions.includes("any") || itemWeatherConditions.includes(tripWeatherCategory)) {
        score += WEIGHTS.weather;
    }

    // 3. Activity scoring
    const itemActivities = item.attributes.activities;
    const userActivities = tripContext.activities;

    if (userActivities.length > 0) {
        const hasActivityMatch = userActivities.some(ua => itemActivities.includes(ua) || itemActivities.includes("any"));
        if (hasActivityMatch) {
            score += WEIGHTS.activity;
        }
    } else if (itemActivities.includes("any")) {
        // Give a small boost to general items if no activities are specified
        score += WEIGHTS.activity / 2;
    }

    return Math.max(0, score); // Ensure score doesn't go below 0
}

/**
 * Generates a packing list based on the trip context.
 * @param {object} tripContext - The context of the trip.
 * @returns {Array} - An array of recommended items.
 */
const getRecommendedItems = (tripContext) => {
    const {
        durationDays,
        avgTemp,
        weatherCode,
        activities,
        lang,
        tripType, // 'domestic' or 'international'
        originCountry, // e.g., 'US', 'CN'
        destination // Add destination for URL processing
    } = tripContext;

    console.log('🔍 Recommendation Debug:');
    console.log('  Trip Type:', tripType);
    console.log('  Origin Country:', originCountry);
    console.log('  Activities:', activities);
    console.log('  Weather Code:', weatherCode);
    console.log('  Avg Temp:', avgTemp);
    console.log('  Total items in database:', items.length);

    const recommended = items.filter(item => {
        const attr = item.attributes;
        
        // --- Trip Type and Country Specific Logic (for essentials like documents) ---
        if (attr.trip_type) {
            if (attr.trip_type !== tripType) {
                console.log(`❌ ${item.id}: Trip type mismatch (${attr.trip_type} vs ${tripType})`);
                return false; // Does not match trip type
            }
            // If it's a domestic trip, we must also match the origin country
            if (tripType === 'domestic' && attr.origin_country && !attr.origin_country.includes(originCountry)) {
                console.log(`❌ ${item.id}: Country mismatch for domestic trip`);
                return false; // Not for this country's domestic travel
            }
            console.log(`✅ ${item.id}: Document item included (trip_type: ${attr.trip_type})`);
            return true;
        }
        
        // --- Existing Logic (for clothes, etc.) ---
        // Check if item has the required attributes for filtering
        const hasActivities = attr.activities && Array.isArray(attr.activities);
        const hasWeather = attr.weather_condition && Array.isArray(attr.weather_condition);
        const hasTemp = attr.temp_min !== undefined && attr.temp_max !== undefined;
        
        console.log(`🔍 ${item.id}: hasActivities=${hasActivities}, hasWeather=${hasWeather}, hasTemp=${hasTemp}`);
        
        // If item has all required attributes, apply full filtering
        if (hasActivities && hasWeather && hasTemp) {
            const matchesActivity = attr.activities.includes('any') || activities.some(activity => attr.activities.includes(activity));
            const matchesWeather = attr.weather_condition.includes('any') || attr.weather_condition.includes(weatherCode);
            const matchesTemp = avgTemp >= attr.temp_min && avgTemp <= attr.temp_max;

            const isIncluded = matchesActivity && matchesWeather && matchesTemp;
            console.log(`  ${item.id}: activity=${matchesActivity}, weather=${matchesWeather}, temp=${matchesTemp} -> ${isIncluded ? '✅' : '❌'}`);
            return isIncluded;
        }
        
        // If item has some but not all attributes, apply partial filtering
        if (hasActivities || hasWeather || hasTemp) {
            let matches = true;
            
            if (hasActivities) {
                const matchesActivity = attr.activities.includes('any') || activities.some(activity => attr.activities.includes(activity));
                matches = matches && matchesActivity;
                console.log(`  ${item.id}: activity=${matchesActivity}`);
            }
            
            if (hasWeather) {
                const matchesWeather = attr.weather_condition.includes('any') || attr.weather_condition.includes(weatherCode);
                matches = matches && matchesWeather;
                console.log(`  ${item.id}: weather=${matchesWeather}`);
            }
            
            if (hasTemp) {
                const matchesTemp = avgTemp >= attr.temp_min && avgTemp <= attr.temp_max;
                matches = matches && matchesTemp;
                console.log(`  ${item.id}: temp=${matchesTemp}`);
            }
            
            console.log(`  ${item.id}: partial filtering -> ${matches ? '✅' : '❌'}`);
            return matches;
        }

        // For items without any specific attributes, include them (fallback)
        console.log(`✅ ${item.id}: No specific attributes, included as fallback`);
        return true;
    });

    console.log(`📋 Total recommended items: ${recommended.length}`);
    recommended.forEach(item => console.log(`  - ${item.id}: ${item.name[lang] || item.name['en']}`));

    return recommended.map(item => {
        let quantity = 1;
        if (item.quantity_logic.type === 'per_day') {
            quantity = Math.ceil(durationDays / item.quantity_logic.value);
        } else if (item.quantity_logic.type === 'fixed') {
            quantity = item.quantity_logic.value;
        }
        
        // Process URL if it exists
        let processedUrl = null;
        if (item.url) {
            processedUrl = item.url.replace('{destination}', encodeURIComponent(destination));
        }
        
        return {
            id: item.id,
            name: item.name[lang] || item.name['en'],
            emoji: item.emoji,
            category: item.category[lang] || item.category['en'],
            quantity: quantity,
            url: processedUrl
        };
    });
};

module.exports = {
    getRecommendedItems,
}; 