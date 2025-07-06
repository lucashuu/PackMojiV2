const fs = require('fs');

// 读取items.json文件
const itemsData = JSON.parse(fs.readFileSync('./backend/items.json', 'utf8'));

console.log('📊 原始物品数量:', itemsData.length);

// 查找重复的物品
const seenIds = new Set();
const duplicates = [];
const uniqueItems = [];

itemsData.forEach((item, index) => {
    if (seenIds.has(item.id)) {
        console.log(`🔴 发现重复物品: ${item.id} - ${item.name.en} (索引: ${index})`);
        duplicates.push({
            id: item.id,
            name: item.name.en,
            index: index
        });
    } else {
        seenIds.add(item.id);
        uniqueItems.push(item);
    }
});

console.log('\n📋 重复物品统计:');
console.log(`- 总物品数: ${itemsData.length}`);
console.log(`- 唯一物品数: ${uniqueItems.length}`);
console.log(`- 重复物品数: ${duplicates.length}`);

if (duplicates.length > 0) {
    console.log('\n🔴 重复物品列表:');
    duplicates.forEach(dup => {
        console.log(`  - ${dup.id}: ${dup.name} (索引: ${dup.index})`);
    });

    // 备份原文件
    const backupFileName = `./backend/items_backup_${Date.now()}.json`;
    fs.writeFileSync(backupFileName, JSON.stringify(itemsData, null, 2));
    console.log(`\n💾 已创建备份文件: ${backupFileName}`);

    // 写入去重后的数据
    fs.writeFileSync('./backend/items.json', JSON.stringify(uniqueItems, null, 2));
    console.log(`\n✅ 已修复重复物品问题！`);
    console.log(`📊 修复后物品数量: ${uniqueItems.length}`);
} else {
    console.log('\n✅ 没有发现重复物品！');
} 