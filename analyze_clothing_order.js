const fs = require('fs');

// 读取items.json
const items = JSON.parse(fs.readFileSync('./backend/items.json', 'utf8'));

// 定义衣物分类
const clothingCategories = {
    tops: ['t_shirt', 'long_sleeve_shirt', 'blouse', 'sweater', 'tank_top', 'base_layer', 'sun_protection_shirt', 'thermal_underwear', 'pajamas', 'swimsuit', 'fancy_dress', 'business_suit', 'rain_poncho', 'light_jacket', 'heavy_jacket', 'hardshell_jacket', 'down_jacket', 'sports_jacket', 'wool_coat', 'ski_jacket'],
    bottoms: ['jeans', 'shorts', 'skirt', 'leggings', 'casual_pants', 'sports_pants', 'quick_dry_pants', 'ski_pants'],
    shoes: ['sneakers', 'sandals', 'boots', 'hiking_boots', 'ski_boots', 'dress_shoes', 'casual_shoes', 'flip_flops', 'formal_shoes', 'water_shoes'],
    underwear: ['underwear', 'sport_bra', 'socks', 'hiking_socks', 'ski_socks']
};

console.log('🔍 分析衣物类物品排序：\n');

// 找到所有衣物类物品
const clothingItems = items.filter(item => 
    item.category.en === 'Clothing/Accessories'
);

console.log(`📊 总共找到 ${clothingItems.length} 个衣物类物品\n`);

// 分析每个分类的物品
Object.keys(clothingCategories).forEach(category => {
    console.log(`📁 ${category.toUpperCase()} (${category === 'tops' ? '上装' : category === 'bottoms' ? '下装' : category === 'shoes' ? '鞋子' : '内衣'}):`);
    
    const categoryItems = clothingItems.filter(item => 
        clothingCategories[category].includes(item.id)
    );
    
    categoryItems.forEach((item, index) => {
        const itemIndex = items.findIndex(i => i.id === item.id);
        console.log(`  ${index + 1}. ${item.emoji} ${item.name.zh} (${item.id}) - 位置: ${itemIndex + 1}`);
    });
    
    console.log('');
});

// 分析整体排序
console.log('📋 衣物类物品在items.json中的完整排序：');
clothingItems.forEach((item, index) => {
    const itemIndex = items.findIndex(i => i.id === item.id);
    let category = '其他';
    
    if (clothingCategories.tops.includes(item.id)) category = '上装';
    else if (clothingCategories.bottoms.includes(item.id)) category = '下装';
    else if (clothingCategories.shoes.includes(item.id)) category = '鞋子';
    else if (clothingCategories.underwear.includes(item.id)) category = '内衣';
    
    console.log(`${index + 1}. ${item.emoji} ${item.name.zh} (${item.id}) - ${category} - 位置: ${itemIndex + 1}`);
});

// 检查是否符合上装-下装-鞋子-内衣的顺序
console.log('\n🔍 检查排序逻辑：');
let currentOrder = [];
let lastCategory = '';

clothingItems.forEach(item => {
    let category = '配饰';
    if (clothingCategories.tops.includes(item.id)) category = '上装';
    else if (clothingCategories.bottoms.includes(item.id)) category = '下装';
    else if (clothingCategories.shoes.includes(item.id)) category = '鞋子';
    else if (clothingCategories.underwear.includes(item.id)) category = '内衣';
    
    if (category !== lastCategory) {
        currentOrder.push(category);
        lastCategory = category;
    }
});

console.log('当前排序顺序：', currentOrder.join(' → '));

const expectedOrder = ['上装', '下装', '鞋子', '内衣', '配饰'];
const isCorrectOrder = currentOrder.join('') === expectedOrder.join('');

console.log('期望排序顺序：', expectedOrder.join(' → '));
console.log(`排序是否正确：${isCorrectOrder ? '✅ 是' : '❌ 否'}`); 