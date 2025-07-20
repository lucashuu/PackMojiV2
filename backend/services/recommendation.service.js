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

// Helper function to sort items by sub-categories
function sortBySubCategories(items, subCategories) {
    const sortedItems = [];
    
    // 按子分类顺序添加物品
    Object.keys(subCategories).forEach(subCategory => {
        const subCategoryItems = items.filter(item => 
            subCategories[subCategory].includes(item.id)
        );
        sortedItems.push(...subCategoryItems);
    });
    
    // 添加任何未分类的物品
    const categorizedIds = new Set(Object.values(subCategories).flat());
    const uncategorizedItems = items.filter(item => !categorizedIds.has(item.id));
    sortedItems.push(...uncategorizedItems);
    
    return sortedItems;
}

// Define item category priorities (higher = more important)
const CATEGORY_PRIORITIES = {
    'Essentials': 100,                      // 必需品 - 最重要（护照、身份证、钱包等）
    'Electronics': 95,                      // 电子产品 - 现代生活必需
    'Clothing/Accessories': 90,             // 衣物/饰品 - 基本需求
    'Beach': 85,                            // 海滩用品 - 活动相关
    'Skiing Equipment': 85,                 // 滑雪装备 - 活动相关
    'Camping': 85,                          // 露营装备 - 活动相关
    'Personal Care/Skincare': 80,           // 个人护理/护肤品 - 日常护理
    'Cosmetics': 75,                        // 化妆品 - 个人形象
    'Miscellaneous': 70,                    // 杂物 - 较低
    'Food & Snacks': 65,                    // 食物零食 - 补充营养
    'Business': 60,                         // 商务用品 - 特定场景需求
    'Comfort': 55,                          // 舒适用品 - 提升旅行体验
    'Medical Kit': 50,                      // 医疗用品 - 健康安全
    // 兼容旧的类别名称
    'Clothing': 90,                         // 兼容旧的衣物类别
    'Accessories': 90,                      // 兼容旧的配饰类别
    'Personal Care': 80,                    // 兼容旧的个人护理类别
    'Skincare': 80                          // 兼容旧的护肤品类别
};

// Essential items that should always be included
const ESSENTIAL_ITEMS = [
    'passport', 'id_card_cn', 'id_card_us', 'credit_card', 'drivers_license', 'student_id', 'cash', 'keys', 
    'visa_info', 'international_driving_permit_info', 'emergency_contacts', 'hotel_reservation', 'flight_reservation',
    'underwear', 'socks', 'pajamas', 'toothbrush_paste', 'face_wash', 'towel', 'sanitary_pads'
];

// Critical documents that should appear at the very top
const CRITICAL_DOCUMENTS = [
    'passport', 'id_card_cn', 'id_card_us', 'drivers_license', 'student_id', 'credit_card'
];

// Documents that should appear first (highest priority)
// This will be dynamically determined based on trip type and origin country
const getHighestPriorityDocuments = (tripType, originCountry) => {
    if (tripType === 'international') {
        return ['passport']; // 国际旅行只显示护照
    } else if (tripType === 'domestic') {
        if (originCountry === 'CN') {
            return ['id_card_cn']; // 中国国内旅行只显示中国身份证
        } else if (originCountry === 'US') {
            return ['id_card_us']; // 美国国内旅行只显示美国身份证/驾照
        } else {
            return ['id_card_cn', 'id_card_us']; // 其他国家的国内旅行显示两种身份证
        }
    }
    return ['passport', 'id_card_cn', 'id_card_us']; // 默认情况
};

// Get documents to exclude based on trip type and origin country
const getExcludedDocuments = (tripType, originCountry) => {
    if (tripType === 'international') {
        return ['id_card_cn', 'id_card_us']; // 国际旅行排除身份证
    } else if (tripType === 'domestic') {
        if (originCountry === 'CN') {
            return ['passport', 'id_card_us']; // 中国国内旅行排除护照和美国身份证
        } else if (originCountry === 'US') {
            return ['passport', 'id_card_cn']; // 美国国内旅行排除护照和中国身份证
        }
    }
    return []; // 默认不排除任何文档
};

// International trip essential items (added dynamically)
const INTERNATIONAL_ESSENTIAL_ITEMS = [
    'visa_info',
    'international_driving_permit_info'
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
    
    // 2b. International Trip Essential Items Boost (0-20 points)
    if (tripContext.tripType === 'international' && INTERNATIONAL_ESSENTIAL_ITEMS.includes(item.id)) {
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
        'Essentials': 25,                   // 必需品：确保重要物品被推荐
        'Electronics': 25,                  // 电子产品：现代生活必需
        'Clothing/Accessories': 30,         // 衣物/饰品：基本需求
        'Beach': 25,                        // 海滩用品：活动相关
        'Skiing Equipment': 25,             // 滑雪装备：活动相关
        'Camping': 25,                      // 露营装备：活动相关
        'Personal Care/Skincare': 30,       // 个人护理/护肤品：日常护理
        'Cosmetics': 25,                    // 化妆品：个人形象
        'Miscellaneous': 20,                // 杂物：较低
        'Food & Snacks': 25,                // 食物零食：补充营养
        'Business': 30,                     // 商务用品：特定场景需求
        'Comfort': 20,                      // 舒适用品：提升旅行体验
        'Medical Kit': 25,                  // 医疗用品：健康安全
        // 兼容旧的类别名称
        'Clothing': 30,                     // 兼容旧的衣物类别
        'Accessories': 20,                  // 兼容旧的配饰类别
        'Personal Care': 30,                // 兼容旧的个人护理类别
        'Skincare': 30                      // 兼容旧的护肤品类别
    };

    // Activity-specific threshold adjustments for professional gear
    const ACTIVITY_THRESHOLD_ADJUSTMENTS = {
        'activity_camping': {
            'Clothing': -10,     // 野营活动下衣物阈值降低10分，确保专业户外衣物被推荐
            'Accessories': -8,   // 野营配件阈值也降低
            'Camping': -10,      // 露营装备阈值降低
            'Medical Kit': -10   // 医疗用品更重要
        },
        'activity_hiking': {
            'Clothing': -12,    // 登山活动下衣物阈值降低12分
            'Accessories': -8,
            'Medical Kit': -10,
            'Miscellaneous': -5
        },
        'activity_skiing': {
            'Clothing': -15,    // 滑雪活动下衣物阈值大幅降低
            'Accessories': -10,
            'Skiing Equipment': -10,
            'Medical Kit': -8
        },
        'activity_beach': {
            'Clothing': -8,     // 海滩活动下衣物阈值稍微降低
            'Beach': -10,
            'Personal Care/Skincare': -5,  // 防晒用品更重要
            'Medical Kit': -8
        },
        'activity_business': {
            'Business': -15,    // 商务活动下商务用品阈值大幅降低
            'Clothing': -5,
            'Electronics': -8
        },
        'activity_city': {
            'Electronics': -5,  // 城市活动下电子产品更重要
            'Comfort': -5,
            'Miscellaneous': -3
        },
        'activity_photography': {
            'Electronics': -10, // 摄影活动下电子产品阈值降低
            'Accessories': -5,
            'Miscellaneous': -5
        },
        'activity_shopping': {
            'Miscellaneous': -8,
            'Comfort': -5
        },
        'activity_party': {
            'Cosmetics': -10,   // 派对活动下化妆品更重要
            'Clothing': -5,
            'Accessories': -5
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
                        SCORE_THRESHOLDS[category] = Math.max(10, SCORE_THRESHOLDS[category] + adjustments[category]);
                    }
                });
            }
        });
    }

    // Get documents to exclude based on trip type and origin country
    const excludedDocuments = getExcludedDocuments(tripType, originCountry);
    
    // Filter items based on score thresholds AND more flexible activity matching
    const recommended = itemsWithScores.filter(item => {
        // Exclude documents based on trip type and origin country
        if (excludedDocuments.includes(item.id)) {
            console.log(`📊 ${item.id}: score=${item.score.toFixed(1)} -> ❌ (excluded for ${tripType} trip from ${originCountry})`);
            return false;
        }
        
        const categoryKey = item.category['en'] || item.category[Object.keys(item.category)[0]];
        const threshold = SCORE_THRESHOLDS[categoryKey] || 25;
        
        // First check if item meets score threshold
        if (item.score < threshold) {
            console.log(`📊 ${item.id}: score=${item.score.toFixed(1)}, threshold=${threshold}, category=${categoryKey} -> ❌ (score too low)`);
            return false;
        }
        
        // 严格的旅行类型匹配：过滤掉不符合旅行类型的物品
        if (item.attributes.trip_type) {
            if (item.attributes.trip_type === 'international' && tripContext.tripType !== 'international') {
                console.log(`📊 ${item.id}: score=${item.score.toFixed(1)}, threshold=${threshold}, category=${categoryKey} -> ❌ (international item for domestic trip)`);
                return false;
            }
            if (item.attributes.trip_type === 'domestic' && tripContext.tripType !== 'domestic') {
                console.log(`📊 ${item.id}: score=${item.score.toFixed(1)}, threshold=${threshold}, category=${categoryKey} -> ❌ (domestic item for international trip)`);
                return false;
            }
        }
        
        // More flexible activity matching - allow items with partial matches or general utility
        if (item.attributes.activities && Array.isArray(item.attributes.activities)) {
            // If item has specific activities (not "any"), check if any match current trip activities
            if (!item.attributes.activities.includes('any')) {
                const hasActivityMatch = tripContext.activities && tripContext.activities.some(userActivity => 
                    item.attributes.activities.includes(userActivity)
                );
                
                // 更宽松的活动匹配：如果分数足够高，即使没有完全匹配也允许通过
                if (!hasActivityMatch) {
                    // 如果分数比阈值高出很多，允许通过（表示这是一个通用的有用物品）
                    const scoreBuffer = item.score - threshold;
                    if (scoreBuffer < 15) {  // 如果分数优势不够大，则过滤掉
                        console.log(`📊 ${item.id}: score=${item.score.toFixed(1)}, threshold=${threshold}, category=${categoryKey} -> ❌ (no activity match, score buffer: ${scoreBuffer.toFixed(1)})`);
                        return false;
                    }
                }
            }
        }
        
        console.log(`📊 ${item.id}: score=${item.score.toFixed(1)}, threshold=${threshold}, category=${categoryKey} -> ✅`);
        return true;
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

    // Apply smart limits to avoid overwhelming the user (按照新的优先级调整数量限制)
    const maxItemsPerCategory = {
        'Essentials': 15,           // 必需品：最重要，保持较高数量
        'Electronics': 12,          // 电子产品：现代生活必需
        'Clothing': 20,             // 衣物：基本需求
        'Clothing/Accessories': 20, // 衣物/饰品：基本需求
        'Beach': 12,                // 海滩用品：活动相关
        'Skiing Equipment': 15,     // 滑雪装备：活动相关
        'Camping': 18,              // 露营装备：活动相关
        'Personal Care': 20,        // 个人护理：日常护理
        'Personal Care/Skincare': 20, // 个人护理/护肤品：日常护理
        'Skincare': 20,              // 护肤品：日常护理
        'Cosmetics': 8,             // 化妆品：个人形象
        'Miscellaneous': 12,        // 杂物：较低
        'Food & Snacks': 8,         // 食物零食：补充营养
        'Business': 12,             // 商务用品：特定场景需求
        'Comfort': 8,               // 舒适用品：提升旅行体验
        'Medical Kit': 15,          // 医疗用品：健康安全
        'Documents': 12,            // 文档：重要但数量有限
        'Accessories': 10,          // 配饰：兼容旧类别            
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
    
    // 获取items.json中物品的原始顺序，用于同一类别内的排序
    const itemOrderMap = {};
    items.forEach((item, index) => {
        itemOrderMap[item.id] = index;
    });
    
    Object.keys(categoryGroups).forEach(categoryKey => {
        const maxItems = maxItemsPerCategory[categoryKey] || 6;
        const categoryItems = categoryGroups[categoryKey]
            .filter(item => !seenIds.has(item.id)) // Remove duplicates
            .slice(0, maxItems);
        
        // 在同一类别内，按照items.json中的原始顺序排序
        categoryItems.sort((a, b) => {
            const aOrder = itemOrderMap[a.id] || 999999;
            const bOrder = itemOrderMap[b.id] || 999999;
            return aOrder - bOrder;
        });
        
        categoryItems.forEach(item => seenIds.add(item.id));
        finalRecommended.push(...categoryItems);
    });

    // 获取动态的最高优先级文档
    const highestPriorityDocs = getHighestPriorityDocuments(tripType, originCountry);
    
    // 最终排序：最高优先级证件最优先，然后其他重要证件，最后按分数排序
    finalRecommended.sort((a, b) => {
        // 1. 最高优先级证件最优先（根据旅行类型和出发国家动态确定）
        const aIsHighest = highestPriorityDocs.includes(a.id);
        const bIsHighest = highestPriorityDocs.includes(b.id);
        
        if (aIsHighest && !bIsHighest) return -1;
        if (!aIsHighest && bIsHighest) return 1;
        
        // 2. 如果都是最高优先级证件，按items.json中的顺序排序
        if (aIsHighest === bIsHighest && aIsHighest) {
            const aOrder = itemOrderMap[a.id] || 999999;
            const bOrder = itemOrderMap[b.id] || 999999;
            return aOrder - bOrder;
        }
        
        // 3. 其他重要证件优先
        const aIsCritical = CRITICAL_DOCUMENTS.includes(a.id);
        const bIsCritical = CRITICAL_DOCUMENTS.includes(b.id);
        
        if (aIsCritical && !bIsCritical) return -1;
        if (!aIsCritical && bIsCritical) return 1;
        
        // 4. 如果都是重要证件，按items.json中的顺序排序
        if (aIsCritical === bIsCritical && aIsCritical) {
            const aOrder = itemOrderMap[a.id] || 999999;
            const bOrder = itemOrderMap[b.id] || 999999;
            return aOrder - bOrder;
        }
        
        // 5. 其他必需品优先
        const aIsEssential = ESSENTIAL_ITEMS.includes(a.id);
        const bIsEssential = ESSENTIAL_ITEMS.includes(b.id);
        
        if (aIsEssential && !bIsEssential) return -1;
        if (!aIsEssential && bIsEssential) return 1;
        
        // 6. 如果都是必需品或都不是必需品，按分数排序
        if (aIsEssential === bIsEssential) {
            if (a.score !== b.score) {
                return b.score - a.score;
            }
        }
        
        // 7. 如果分数相同，按items.json中的顺序排序
        const aOrder = itemOrderMap[a.id] || 999999;
        const bOrder = itemOrderMap[b.id] || 999999;
        return aOrder - bOrder;
    });

    console.log(`📋 Final recommended items: ${finalRecommended.length}`);
    console.log(`📊 Score distribution:`);
    finalRecommended.forEach(item => {
        const categoryKey = item.category['en'] || item.category[Object.keys(item.category)[0]];
        console.log(`  - ${item.id}: ${item.score.toFixed(1)} pts (${categoryKey})`);
    });

    // Group items by category for better organization
    const groupedItems = {};
    finalRecommended.forEach(item => {
        let quantity = 1;
        if (item.quantity_logic.type === 'per_day') {
            quantity = Math.ceil(durationDays * item.quantity_logic.value);
        } else if (item.quantity_logic.type === 'fixed') {
            quantity = item.quantity_logic.value;
        }
        
        // Process URL if it exists - add to note field
        let processedUrl = null;
        let noteText = null;
        if (item.url) {
            processedUrl = item.url.replace('{destination}', encodeURIComponent(destination));
            // Add URL to note field for easy access
            if (lang === 'zh') {
                noteText = `搜索链接：${processedUrl}`;
            } else {
                noteText = `Search link: ${processedUrl}`;
            }
        }
        
        const processedItem = {
            id: item.id,
            name: item.name[lang] || item.name['en'],
            emoji: item.emoji,
            category: item.category[lang] || item.category['en'],
            quantity: quantity,
            note: noteText,
            url: processedUrl,
            score: item.score // Include score for debugging
        };
        
        // Group by category
        const categoryKey = item.category[lang] || item.category['en'];
        if (!groupedItems[categoryKey]) {
            groupedItems[categoryKey] = [];
        }
        groupedItems[categoryKey].push(processedItem);
    });
    
    // Convert grouped items to array format with group information
    const result = [];
    Object.keys(groupedItems).forEach(category => {
        let items = groupedItems[category];
        
        // 对所有类别进行分组排序
        if (category === 'Clothing/Accessories' || category === '衣物/饰品') {
            // 衣物类分组排序 - 从薄到厚（从内到外）
            const clothingSubCategories = {
                underwear: ['underwear', 'sport_bra', 'thermal_underwear', 'base_layer', 'socks', 'hiking_socks', 'ski_socks'],
                inner_tops: ['tank_top', 't_shirt', 'long_sleeve_shirt', 'blouse', 'sun_protection_shirt'],
                inner_bottoms: ['leggings', 'shorts', 'skirt'],
                middle_layer: ['sweater', 'casual_pants', 'jeans', 'sports_pants', 'quick_dry_pants'],
                outer_tops: ['light_jacket', 'sports_jacket', 'heavy_jacket', 'hardshell_jacket', 'down_jacket', 'wool_coat', 'ski_jacket'],
                outer_bottoms: ['ski_pants'],
                special_wear: ['pajamas', 'swimsuit', 'fancy_dress', 'business_suit', 'rain_poncho'],
                shoes: ['flip_flops', 'sandals', 'sneakers', 'casual_shoes', 'dress_shoes', 'formal_shoes', 'boots', 'hiking_boots', 'water_shoes', 'ski_boots'],
                accessories: ['belt', 'scarf', 'gloves', 'hiking_gloves', 'ski_gloves', 'neck_warmer', 'winter_hat', 'hat_cap', 'sunglasses', 'jewelry', 'tie', 'evening_bag', 'hiking_backpack', 'hair_styling_tools', 'ski_helmet', 'ski_goggles']
            };
            
            items = sortBySubCategories(items, clothingSubCategories);
        } else if (category === 'Essentials' || category === '必需品') {
            // 必需品分组排序
            const essentialsSubCategories = {
                documents: ['passport', 'id_card_cn', 'id_card_us', 'drivers_license', 'student_id', 'credit_card'],
                money: ['cash'],
                travel_info: ['visa_info', 'international_driving_permit_info', 'flight_reservation', 
                             'hotel_reservation', 'rental_car_reservation', 'attraction_reservation', 
                             'insurance_documents'],
                keys: ['keys'],
                contacts: ['emergency_contacts']
            };
            
            items = sortBySubCategories(items, essentialsSubCategories);
        } else if (category === 'Electronics' || category === '电子产品') {
            // 电子产品分组排序
            const electronicsSubCategories = {
                phones: ['phone', 'phone_charger', 'power_bank'],
                computers: ['laptop', 'laptop_charger', 'ipad', 'ipad_charger'],
                cameras: ['camera', 'camera_charger', 'camera_battery', 'memory_card', 'tripod', 'drone', 
                         'action_camera', 'smartphone_gimbal'],
                audio: ['headphones', 'wireless_earbuds', 'portable_speaker'],
                accessories: ['smartwatch', 'e_reader', 'walkie_talkie', 'travel_adapter', 'power_strip', 
                            'usb_cable', 'compass_gps', 'headlamp']
            };
            
            items = sortBySubCategories(items, electronicsSubCategories);
        } else if (category === 'Personal Care/Skincare' || category === '个人护理/护肤品') {
            // 个人护理分组排序
            const personalCareSubCategories = {
                hygiene: ['toothbrush_paste', 'mouthwash', 'water_flosser', 'shower_gel', 'towel'],
                skincare: ['face_wash', 'toner', 'moisturizer', 'hand_cream', 'body_lotion', 'eye_cream', 
                          'face_mask', 'essence'],
                grooming: ['shampoo', 'deodorant', 'razor', 'nail_clippers', 'comb', 'hair_ties'],
                essentials: ['glasses', 'contact_lenses', 'wet_wipes', 'tissues', 'hand_sanitizer', 
                           'slippers', 'heating_pad', 'sanitary_pads', 'contraceptives', 'pregnancy_test']
            };
            
            items = sortBySubCategories(items, personalCareSubCategories);
        } else if (category === 'Cosmetics' || category === '化妆品') {
            // 化妆品分组排序
            const cosmeticsSubCategories = {
                base: ['foundation', 'concealer', 'powder', 'primer'],
                eyes: ['eyeshadow', 'eyeliner', 'mascara', 'eyebrow_pencil'],
                lips: ['lipstick', 'lip_balm'],
                tools: ['makeup_brushes', 'cotton_pads', 'makeup_remover'],
                extras: ['sunscreen', 'skincare', 'makeup', 'perfume_cologne', 'contour', 'highlighter', 
                        'setting_spray']
            };
            
            items = sortBySubCategories(items, cosmeticsSubCategories);
        } else if (category === 'Medical Kit' || category === '医疗用品') {
            // 医疗用品分组排序
            const medicalSubCategories = {
                first_aid: ['band_aids', 'medical_tape', 'alcohol_wipes', 'antiseptic', 'first_aid_kit'],
                medications: ['pain_relievers', 'painkillers', 'personal_medications'],
                monitoring: ['thermometer'],
                protection: ['medical_mask', 'mosquito_repellent']
            };
            
            items = sortBySubCategories(items, medicalSubCategories);
        } else if (category === 'Camping' || category === '露营装备') {
            // 露营装备分组排序
            const campingSubCategories = {
                shelter: ['tent', 'sleeping_bag', 'sleeping_pad'],
                cooking: ['camping_stove', 'camping_cookware', 'camping_utensils', 'matches_lighter'],
                comfort: ['camping_chair', 'camping_lantern', 'cooler'],
                tools: ['paracord']
            };
            
            items = sortBySubCategories(items, campingSubCategories);
        } else if (category === 'Skiing Equipment' || category === '滑雪装备') {
            // 滑雪装备分组排序
            const skiingSubCategories = {
                protection: ['ski_helmet', 'ski_goggles', 'ski_gloves'],
                equipment: ['ski_boots', 'ski_poles', 'skis', 'ski_bindings', 'ski_wax'],
                accessories: ['ski_bag', 'ski_pass']
            };
            
            items = sortBySubCategories(items, skiingSubCategories);
        } else if (category === 'Beach' || category === '海滩用品') {
            // 海滩用品分组排序
            const beachSubCategories = {
                towels: ['beach_towel'],
                protection: ['beach_umbrella'],
                accessories: ['beach_bag', 'snorkel_gear', 'waterproof_phone_case']
            };
            
            items = sortBySubCategories(items, beachSubCategories);
        } else if (category === 'Business' || category === '商务用品') {
            // 商务用品分组排序
            const businessSubCategories = {
                documents: ['business_cards', 'notepad'],
                accessories: ['briefcase']
            };
            
            items = sortBySubCategories(items, businessSubCategories);
        } else if (category === 'Comfort' || category === '舒适用品') {
            // 舒适用品分组排序
            const comfortSubCategories = {
                sleep: ['travel_pillow', 'eye_mask', 'earplugs'],
                warmth: ['travel_blanket']
            };
            
            items = sortBySubCategories(items, comfortSubCategories);
        } else if (category === 'Food & Snacks' || category === '食物零食') {
            // 食物零食分组排序
            const foodSubCategories = {
                snacks: ['travel_snacks', 'energy_bars', 'nuts'],
                drinks: ['instant_coffee', 'drinking_water', 'electrolyte_powder']
            };
            
            items = sortBySubCategories(items, foodSubCategories);
        } else if (category === 'Miscellaneous' || category === '杂物') {
            // 杂物分组排序
            const miscSubCategories = {
                bags: ['tote_bag', 'laundry_bags', 'zip_lock_bags'],
                luggage: ['luggage_tags', 'luggage_locks', 'portable_scale'],
                tools: ['hiking_poles', 'water_bottle', 'multi_tool', 'emergency_whistle'],
                weather: ['umbrella', 'hand_warmers']
            };
            
            items = sortBySubCategories(items, miscSubCategories);
        }
        
        result.push({
            group: category,
            items: items
        });
    });
    
    return result;
};

module.exports = {
    getRecommendedItems,
};