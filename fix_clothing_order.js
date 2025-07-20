const fs = require('fs');

// 读取items.json
const items = JSON.parse(fs.readFileSync('./backend/items.json', 'utf8'));

// 定义衣物分类和排序
const clothingCategories = {
    tops: [
        't_shirt', 'long_sleeve_shirt', 'blouse', 'sweater', 'tank_top', 'base_layer', 
        'sun_protection_shirt', 'thermal_underwear', 'pajamas', 'swimsuit', 'fancy_dress', 
        'business_suit', 'rain_poncho', 'light_jacket', 'heavy_jacket', 'hardshell_jacket', 
        'down_jacket', 'sports_jacket', 'wool_coat', 'ski_jacket'
    ],
    bottoms: [
        'jeans', 'shorts', 'skirt', 'leggings', 'casual_pants', 'sports_pants', 
        'quick_dry_pants', 'ski_pants'
    ],
    shoes: [
        'sneakers', 'sandals', 'boots', 'hiking_boots', 'dress_shoes', 'casual_shoes', 
        'flip_flops', 'formal_shoes', 'water_shoes', 'ski_boots'
    ],
    underwear: [
        'socks', 'underwear', 'sport_bra', 'hiking_socks', 'ski_socks'
    ],
    accessories: [
        'scarf', 'gloves', 'belt', 'sunglasses', 'jewelry', 'tie', 'winter_hat', 
        'hat_cap', 'hiking_gloves', 'neck_warmer', 'evening_bag', 'hiking_backpack', 
        'hair_styling_tools', 'ski_helmet', 'ski_goggles', 'ski_gloves'
    ]
};

// 找到所有衣物类物品
const clothingItems = items.filter(item => 
    item.category.en === 'Clothing/Accessories'
);

console.log(`📊 找到 ${clothingItems.length} 个衣物类物品`);

console.log('🔍 修复衣物类物品排序：\n');

// 按新顺序重新排列衣物类物品
const reorderedClothing = [];

// 1. 上装
clothingCategories.tops.forEach(id => {
    const item = clothingItems.find(item => item.id === id);
    if (item) reorderedClothing.push(item);
});

// 2. 下装
clothingCategories.bottoms.forEach(id => {
    const item = clothingItems.find(item => item.id === id);
    if (item) reorderedClothing.push(item);
});

// 3. 鞋子
clothingCategories.shoes.forEach(id => {
    const item = clothingItems.find(item => item.id === id);
    if (item) reorderedClothing.push(item);
});

// 4. 内衣
clothingCategories.underwear.forEach(id => {
    const item = clothingItems.find(item => item.id === id);
    if (item) reorderedClothing.push(item);
});

// 5. 配饰
clothingCategories.accessories.forEach(id => {
    const item = clothingItems.find(item => item.id === id);
    if (item) reorderedClothing.push(item);
});

console.log('📋 重新排序后的衣物类物品：');
reorderedClothing.forEach((item, index) => {
    let category = '配饰';
    if (clothingCategories.tops.includes(item.id)) category = '上装';
    else if (clothingCategories.bottoms.includes(item.id)) category = '下装';
    else if (clothingCategories.shoes.includes(item.id)) category = '鞋子';
    else if (clothingCategories.underwear.includes(item.id)) category = '内衣';
    
    console.log(`${index + 1}. ${item.emoji} ${item.name.zh} (${item.id}) - ${category}`);
});

// 更新items.json中的顺序
console.log('\n🔄 更新items.json中的顺序...');

// 找到所有衣物类物品在items.json中的位置
const clothingIndices = [];
clothingItems.forEach(item => {
    const index = items.findIndex(i => i.id === item.id);
    clothingIndices.push({ item, originalIndex: index });
});

// 按原始索引排序，然后替换为新的顺序
clothingIndices.sort((a, b) => a.originalIndex - b.originalIndex);

// 替换items.json中的衣物类物品
let reorderedItems = [...items];
clothingIndices.forEach((clothingItem, index) => {
    const newItem = reorderedClothing[index];
    if (newItem) {
        reorderedItems[clothingItem.originalIndex] = newItem;
    }
});

// 确保所有衣物类物品都在正确的位置
console.log('🔍 检查是否所有衣物类物品都已排序...');
const remainingClothingItems = items.filter(item => 
    item.category.en === 'Clothing/Accessories' && 
    !reorderedClothing.find(reordered => reordered.id === item.id)
);

if (remainingClothingItems.length > 0) {
    console.log(`⚠️  发现 ${remainingClothingItems.length} 个未排序的衣物类物品：`);
    remainingClothingItems.forEach(item => {
        console.log(`  - ${item.emoji} ${item.name.zh} (${item.id})`);
    });
    
    // 将这些未排序的物品添加到配饰类别中
    remainingClothingItems.forEach(item => {
        reorderedClothing.push(item);
    });
}

// 保存更新后的items.json
fs.writeFileSync('./backend/items_reordered.json', JSON.stringify(reorderedItems, null, 2));

console.log('✅ 已保存重新排序的items.json到 items_reordered.json');
console.log(`📊 总共重新排序了 ${reorderedClothing.length} 个衣物类物品`);

// 验证排序
console.log('\n🔍 验证新排序：');
let currentOrder = [];
let lastCategory = '';

reorderedClothing.forEach(item => {
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

console.log('新排序顺序：', currentOrder.join(' → '));
const expectedOrder = ['上装', '下装', '鞋子', '内衣', '配饰'];
const isCorrectOrder = currentOrder.join('') === expectedOrder.join('');

console.log('期望排序顺序：', expectedOrder.join(' → '));
console.log(`排序是否正确：${isCorrectOrder ? '✅ 是' : '❌ 否'}`); 