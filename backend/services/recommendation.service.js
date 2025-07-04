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

// Define item category priorities (higher = more important)
const CATEGORY_PRIORITIES = {
    'Documents': 100,           // 证件文件 - 最重要
    'Medical Kit': 90,          // 医疗用品 - 很重要  
    'Personal Care': 80,        // 个人护理 - 重要
    'Toiletries': 75,           // 日常洗漱 - 重要
    'Clothing': 70,             // 衣物 - 重要
    'Electronics': 65,          // 电子产品 - 较重要
    'Food & Snacks': 60,        // 食物零食 - 中等
    'Essentials': 85,           // 必需品 - 很重要
    'Comfort': 50,              // 舒适用品 - 中等
    'Accessories': 45,          // 配饰 - 中等
    'Miscellaneous': 40,        // 杂物 - 较低
    'Beach': 35,                // 海滩用品 - 活动相关
    'Business': 35,             // 商务用品 - 活动相关
    'Camping Equipment': 35,    // 露营装备 - 活动相关
    'Skiing Equipment': 35,     // 滑雪装备 - 活动相关
    'Cosmetics': 30,            // 化妆品 - 较低
    'Skincare': 25              // 护肤品 - 较低
};

// Essential items that should always be included
const ESSENTIAL_ITEMS = [
    'passport', 'id_card', 'tickets', 'cash', 'underwear', 'socks', 'pajamas',
    'toothbrush_paste', 'face_wash', 'towel', 'sanitary_pads', 'band_aids'
];

/**
 * Enhanced match score calculation with multiple factors
 * @param {object} item - The item from the database.
 * @param {object} tripContext - The context of the trip.
 * @returns {number} - A score between 0 and 100.
 */
function calculateMatchScore(item, tripContext) {
    let score = 0;
    const attr = item.attributes;
    
    // Enhanced weights for better recommendations
    const WEIGHTS = {
        category: 25,      // Category priority weight
        essential: 20,     // Essential item boost
        activity: 20,      // Activity match weight  
        weather: 15,       // Weather match weight
        temperature: 10,   // Temperature match weight
        trip_type: 10      // Trip type match weight
    };

    // 1. Category Priority Score (0-25 points)
    const categoryKey = item.category['en'] || item.category[Object.keys(item.category)[0]]; // Get English category value
    const categoryPriority = CATEGORY_PRIORITIES[categoryKey] || 30;
    score += (categoryPriority / 100) * WEIGHTS.category;

    // 2. Essential Items Boost (0-20 points)
    if (ESSENTIAL_ITEMS.includes(item.id)) {
        score += WEIGHTS.essential;
    }

    // 3. Activity Match Score (0-20 points)
    if (attr.activities && Array.isArray(attr.activities)) {
        if (attr.activities.includes('any')) {
            score += WEIGHTS.activity * 0.3; // Universal items get partial score
        } else if (tripContext.activities && tripContext.activities.length > 0) {
            const activityMatches = tripContext.activities.filter(ua => attr.activities.includes(ua)).length;
            const activityScore = Math.min(1, activityMatches / tripContext.activities.length);
            score += WEIGHTS.activity * activityScore;
        }
    }

    // 4. Weather Condition Score (0-15 points)
    if (attr.weather_condition && Array.isArray(attr.weather_condition)) {
        const tripWeatherCategory = weatherConditionMap[tripContext.weatherCode] || 'any';
        if (attr.weather_condition.includes('any')) {
            score += WEIGHTS.weather * 0.5; // Universal items get partial score
        } else if (attr.weather_condition.includes(tripWeatherCategory)) {
            score += WEIGHTS.weather;
        }
    }

    // 5. Temperature Range Score (0-10 points)
    if (attr.temp_min !== undefined && attr.temp_max !== undefined) {
        const tempRange = attr.temp_max - attr.temp_min;
        const tempCenter = (attr.temp_min + attr.temp_max) / 2;
        const tempDiff = Math.abs(tripContext.avgTemp - tempCenter);
        
        if (tripContext.avgTemp >= attr.temp_min && tripContext.avgTemp <= attr.temp_max) {
            // Perfect match - full points
            score += WEIGHTS.temperature;
        } else if (tempDiff <= 5) {
            // Close match - partial points
            score += WEIGHTS.temperature * (1 - tempDiff / 5) * 0.7;
        }
    }

    // 6. Trip Type Match (0-10 points)
    if (attr.trip_type) {
        if (attr.trip_type === tripContext.tripType) {
            score += WEIGHTS.trip_type;
            // Bonus for country match on domestic trips
            if (tripContext.tripType === 'domestic' && attr.origin_country && 
                attr.origin_country.includes(tripContext.originCountry)) {
                score += 5; // Extra bonus
            }
        }
    } else {
        score += WEIGHTS.trip_type * 0.3; // Non-document items get partial score
    }

    // 7. Seasonal and Duration Bonuses
    if (tripContext.durationDays) {
        // Comfort items get higher scores for longer trips
        if (categoryKey === 'Comfort' && tripContext.durationDays > 7) {
            score += 5;
        }
        // Medical items get higher scores for longer trips
        if (categoryKey === 'Medical Kit' && tripContext.durationDays > 5) {
            score += 3;
        }
    }

    return Math.min(100, Math.max(0, score)); // Clamp between 0-100
}

/**
 * Generates a packing list based on the trip context using scoring system.
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
        tripType,
        originCountry,
        destination
    } = tripContext;

    console.log('🔍 Enhanced Recommendation Debug:');
    console.log('  Trip Type:', tripType);
    console.log('  Origin Country:', originCountry);
    console.log('  Activities:', activities);
    console.log('  Weather Code:', weatherCode);
    console.log('  Avg Temp:', avgTemp);
    console.log('  Duration:', durationDays, 'days');
    console.log('  Total items in database:', items.length);

    // Calculate scores for all items
    const itemsWithScores = items.map(item => {
        const score = calculateMatchScore(item, tripContext);
        return {
            ...item,
            score: score
        };
    });

    // Define base score thresholds for different categories (降低阈值以提高推荐覆盖率)
    const BASE_SCORE_THRESHOLDS = {
        'Documents': 45,        // 证件类：降低阈值确保护照等重要文件被推荐
        'Medical Kit': 55,      // 医疗用品：稍微降低但保持重要性
        'Personal Care': 50,    // 个人护理：适度降低
        'Toiletries': 45,       // 日用品：降低以确保基本洗漱用品被推荐
        'Clothing': 40,         // 衣物：大幅降低以确保基本衣物被推荐
        'Electronics': 35,      // 电子产品：大幅降低确保手机、充电器等被推荐
        'Food & Snacks': 35,    // 食物零食：降低阈值
        'Essentials': 40,       // 必需品：大幅降低确保现金等被推荐
        'Comfort': 30,          // 舒适用品：稍微降低
        'Accessories': 25,      // 配件：保持较低
        'Miscellaneous': 20,    // 杂物：保持较低
        'Beach': 35,            // 海滩用品：降低以确保活动匹配时被推荐
        'Business': 35,         // 商务用品：降低以确保活动匹配时被推荐
        'Camping Equipment': 35, // 露营装备：降低以确保活动匹配时被推荐
        'Camping': 35,          // 露营装备：降低以确保活动匹配时被推荐
        'Skiing Equipment': 30,  // 滑雪装备：专业设备优先推荐
        'Cosmetics': 20,        // 化妆品：保持较低
        'Skincare': 15,         // 护肤品：保持较低
        'Medicine': 40          // 药品：新增分类，中等阈值
    };

    // Activity-specific threshold adjustments for professional gear
    const ACTIVITY_THRESHOLD_ADJUSTMENTS = {
        'activity_camping': {
            'Clothing': -8,     // 野营活动下衣物阈值降低8分，确保专业户外衣物被推荐
            'Accessories': -5   // 野营配件阈值也降低
        },
        'activity_hiking': {
            'Clothing': -10,    // 登山活动下衣物阈值降低10分
            'Accessories': -5
        },
        'activity_skiing': {
            'Clothing': -12,    // 滑雪活动下衣物阈值大幅降低
            'Accessories': -8
        },
        'activity_beach': {
            'Clothing': -5,     // 海滩活动下衣物阈值稍微降低
            'Beach': -5
        }
    };

    // Calculate dynamic thresholds based on activities
    const SCORE_THRESHOLDS = { ...BASE_SCORE_THRESHOLDS };
    if (activities && activities.length > 0) {
        activities.forEach(activity => {
            const adjustments = ACTIVITY_THRESHOLD_ADJUSTMENTS[activity];
            if (adjustments) {
                Object.keys(adjustments).forEach(category => {
                    if (SCORE_THRESHOLDS[category]) {
                        SCORE_THRESHOLDS[category] = Math.max(15, SCORE_THRESHOLDS[category] + adjustments[category]);
                    }
                });
            }
        });
    }

    // Filter items based on score thresholds
    const recommended = itemsWithScores.filter(item => {
        const categoryKey = item.category['en'] || item.category[Object.keys(item.category)[0]];
        const threshold = SCORE_THRESHOLDS[categoryKey] || 35;
        const isRecommended = item.score >= threshold;
        
        console.log(`📊 ${item.id}: score=${item.score.toFixed(1)}, threshold=${threshold}, category=${categoryKey} -> ${isRecommended ? '✅' : '❌'}`);
        return isRecommended;
    });

    // Sort by score (highest first) and ensure essential items are prioritized
    recommended.sort((a, b) => {
        // Essential items always come first regardless of score
        const aIsEssential = ESSENTIAL_ITEMS.includes(a.id);
        const bIsEssential = ESSENTIAL_ITEMS.includes(b.id);
        
        if (aIsEssential && !bIsEssential) return -1;
        if (!aIsEssential && bIsEssential) return 1;
        
        // Then sort by score
        return b.score - a.score;
    });

    // Apply smart limits to avoid overwhelming the user
    const maxItemsPerCategory = {
        'Documents': 10,
        'Medical Kit': 8,
        'Personal Care': 10,
        'Toiletries': 8,
        'Clothing': 15,
        'Electronics': 8,
        'Food & Snacks': 6,
        'Essentials': 12,
        'Comfort': 5,
        'Accessories': 6,
        'Miscellaneous': 8,
        'Beach': 8,
        'Business': 8,
        'Camping Equipment': 12,  // 增加camping装备限制
        'Camping': 12,            // 添加Camping分类限制
        'Skiing Equipment': 10,
        'Cosmetics': 5,
        'Skincare': 3
    };

    // Group by category and apply limits
    const categoryGroups = {};
    recommended.forEach(item => {
        const categoryKey = item.category['en'] || item.category[Object.keys(item.category)[0]];
        if (!categoryGroups[categoryKey]) {
            categoryGroups[categoryKey] = [];
        }
        categoryGroups[categoryKey].push(item);
    });

    // Apply limits and flatten back to array
    const finalRecommended = [];
    const seenIds = new Set(); // Track item IDs to prevent duplicates
    
    Object.keys(categoryGroups).forEach(categoryKey => {
        const maxItems = maxItemsPerCategory[categoryKey] || 6;
        const categoryItems = categoryGroups[categoryKey]
            .filter(item => !seenIds.has(item.id)) // Remove duplicates
            .slice(0, maxItems);
        
        categoryItems.forEach(item => seenIds.add(item.id));
        finalRecommended.push(...categoryItems);
    });

    console.log(`📋 Final recommended items: ${finalRecommended.length}`);
    console.log(`📊 Score distribution:`);
    finalRecommended.forEach(item => {
        const categoryKey = item.category['en'] || item.category[Object.keys(item.category)[0]];
        console.log(`  - ${item.id}: ${item.score.toFixed(1)} pts (${categoryKey})`);
    });

    // Transform to final format
    return finalRecommended.map(item => {
        let quantity = 1;
        if (item.quantity_logic.type === 'per_day') {
            quantity = Math.ceil(durationDays * item.quantity_logic.value);
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
            url: processedUrl,
            score: item.score // Include score for debugging
        };
    });
};

module.exports = {
    getRecommendedItems,
}; 