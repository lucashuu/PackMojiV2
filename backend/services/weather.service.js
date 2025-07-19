require('dotenv').config();
const axios = require('axios');

const API_KEY = process.env.OPENWEATHER_API_KEY;
const GEOCODE_URL = 'http://api.openweathermap.org/geo/1.0/direct';
const WEATHER_URL = 'https://api.openweathermap.org/data/3.0/onecall';

/**
 * Fetches intelligent weather data combining real forecast and historical averages.
 * - Within forecast range (0-7 days): Shows real weather forecast
 * - Beyond forecast range: Shows historical monthly averages
 */
const getWeatherData = async (destination, startDate, endDate, lang = 'en') => {
    if (!API_KEY) {
        throw new Error('OpenWeather API key is not configured. Please set OPENWEATHER_API_KEY in .env file.');
    }
    console.log(`🌤️ Fetching intelligent weather data for ${destination}...`);

    const language = lang.startsWith('zh') ? 'zh' : 'en';

    try {
        // 1. Geocoding
        const geoResponse = await axios.get(GEOCODE_URL, {
            params: { q: destination, limit: 1, appid: API_KEY }
        });

        if (!geoResponse.data || geoResponse.data.length === 0) {
            throw new Error(`Could not find location: ${destination}`);
        }
        const { lat, lon } = geoResponse.data[0];

        // 2. Get trip duration and generate all trip days
        const tripStart = new Date(startDate);
        const tripEnd = new Date(endDate);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        const allTripDays = [];
        for (let d = new Date(tripStart); d <= tripEnd; d.setDate(d.getDate() + 1)) {
            allTripDays.push(new Date(d));
        }

        console.log(`📅 Trip duration: ${allTripDays.length} days`);

        // 3. Fetch 8-day forecast
        const weatherResponse = await axios.get(WEATHER_URL, {
            params: { lat, lon, exclude: 'current,minutely,hourly,alerts', appid: API_KEY, units: 'metric', lang: language }
        });

        if (!weatherResponse.data || !weatherResponse.data.daily) {
            throw new Error('Invalid weather data received from API.');
        }

        // 4. Process forecast data and determine forecast coverage
        const forecastData = weatherResponse.data.daily;
        const forecastEndDate = new Date(today);
        forecastEndDate.setDate(forecastEndDate.getDate() + 7); // 7-day forecast coverage

        console.log(`🔮 Forecast coverage: ${today.toISOString().split('T')[0]} to ${forecastEndDate.toISOString().split('T')[0]}`);

        // 5. Build daily weather array with mixed data
        const dailyWeatherArray = [];
        const allTemperatures = [];
        const allConditions = [];

        for (const dayDate of allTripDays) {
            const dayDateStr = dayDate.toISOString().split('T')[0];
            const dayOfWeek = getDayOfWeek(dayDate.getDay(), language);
            
            if (dayDate <= forecastEndDate) {
                // Within forecast range - use real forecast data
                const forecastDay = forecastData.find(day => {
                    const forecastDate = new Date(day.dt * 1000);
                    return forecastDate.toISOString().split('T')[0] === dayDateStr;
                });

                if (forecastDay) {
                    const temp = Math.round(forecastDay.temp.day);
                    const condition = forecastDay.weather[0].description;
                    const conditionCode = forecastDay.weather[0].main.toLowerCase();
                    const icon = forecastDay.weather[0].icon;

                    dailyWeatherArray.push({
                        date: dayDateStr,
                        dayOfWeek,
                        temperature: temp,
                        condition: condition,
                        conditionCode: conditionCode,
                        icon: icon,
                        dataSource: 'forecast'
                    });

                    allTemperatures.push(temp);
                    allConditions.push(conditionCode);
                    console.log(`📊 ${dayDateStr}: ${temp}°C, ${condition} (预报)`);
                } else {
                    // Fallback to historical data if forecast not available for this day
                    const historicalDay = await getHistoricalDayData(lat, lon, dayDate, language);
                    dailyWeatherArray.push(historicalDay);
                    allTemperatures.push(historicalDay.temperature);
                    allConditions.push(historicalDay.conditionCode);
                }
            } else {
                // Beyond forecast range - use historical monthly average
                const historicalDay = await getHistoricalMonthlyAverage(lat, lon, dayDate, language);
                dailyWeatherArray.push(historicalDay);
                allTemperatures.push(historicalDay.temperature);
                allConditions.push(historicalDay.conditionCode);
            }
        }

        // 6. Calculate overall trip averages
        const averageTemp = Math.round(allTemperatures.reduce((sum, temp) => sum + temp, 0) / allTemperatures.length);
        
        const conditionCounts = allConditions.reduce((counts, condition) => {
            counts[condition] = (counts[condition] || 0) + 1;
            return counts;
        }, {});
        const dominantConditionCode = Object.keys(conditionCounts).reduce((a, b) => conditionCounts[a] > conditionCounts[b] ? a : b);
        const dominantCondition = dailyWeatherArray.find(d => d.conditionCode === dominantConditionCode).condition;

        // 7. Check if data is mixed (contains both forecast and historical)
        const forecastDays = dailyWeatherArray.filter(d => d.dataSource === 'forecast').length;
        const historicalDays = dailyWeatherArray.filter(d => d.dataSource === 'historical').length;
        const isMixedData = forecastDays > 0 && historicalDays > 0;

        console.log(`📈 Weather Summary: ${averageTemp}°C, ${dominantCondition}`);
        console.log(`📊 Data composition: ${forecastDays} forecast days, ${historicalDays} historical days`);

        // 8. Generate monthly averages for historical data
        let monthlyAverages = [];
        if (historicalDays > 0) {
            const monthsInTrip = getMonthsInTrip(tripStart, tripEnd);
            console.log(`📅 Trip spans ${monthsInTrip.length} months:`, monthsInTrip.map(m => m.name));
            
            for (const month of monthsInTrip) {
                try {
                    const monthlyData = await getMonthlyAverageData(lat, lon, month, language);
                    monthlyAverages.push(monthlyData);
                    console.log(`📊 Monthly average for ${month.name}: ${monthlyData.temperature}°C, ${monthlyData.condition}`);
                } catch (error) {
                    console.warn(`Unable to fetch monthly average for ${month.name}, using fallback`);
                    monthlyAverages.push({
                        monthName: month.name,
                        temperature: 20,
                        condition: "weather_historical_monthly_average",
                        conditionCode: "clouds",
                        icon: "02d"
                    });
                }
            }
        }

        return {
            averageTemp,
            condition: dominantCondition,
            conditionCode: dominantConditionCode,
            dailyWeather: dailyWeatherArray,
            isHistorical: historicalDays > 0,
            isMixedData: isMixedData,
            forecastDays: forecastDays,
            historicalDays: historicalDays,
            monthlyAverages: monthlyAverages
        };

    } catch (error) {
        console.error("Error fetching weather data:", error.response ? error.response.data : error.message);
        // Fallback to mock data in case of any error
        const mockDays = generateMockDailyWeather(startDate, endDate);
        return {
            averageTemp: 15,
            condition: "多云",
            conditionCode: "clouds",
            dailyWeather: mockDays,
            isHistorical: false,
            isMixedData: false,
            forecastDays: mockDays.length,
            historicalDays: 0,
            monthlyAverages: []
        };
    }
};

/**
 * Get historical weather data for a specific day from last year
 */
const getHistoricalDayData = async (lat, lon, dayDate, language) => {
    const lastYearDate = new Date(dayDate);
    lastYearDate.setFullYear(lastYearDate.getFullYear() - 1);
    
    const dateStr = lastYearDate.toISOString().split('T')[0];
    const dayOfWeek = getDayOfWeek(dayDate.getDay(), language);

    try {
        const historicalData = await getHistoricalWeatherData(lat, lon, dateStr, dateStr, language);
        const dayData = historicalData.dailyWeather[0];
        
        return {
            date: dayDate.toISOString().split('T')[0],
            dayOfWeek: dayOfWeek,
            temperature: dayData.temperature,
            condition: dayData.condition,
            conditionCode: dayData.conditionCode,
            icon: dayData.icon,
            dataSource: 'historical'
        };
    } catch (error) {
        console.warn(`Unable to fetch historical data for ${dateStr}, using average`);
        return {
            date: dayDate.toISOString().split('T')[0],
            dayOfWeek: dayOfWeek,
            temperature: 20,
            condition: "historical_average",
            conditionCode: "clouds",
            icon: "02d",
            dataSource: 'historical'
        };
    }
};

/**
 * Get historical monthly average for a specific day
 */
const getHistoricalMonthlyAverage = async (lat, lon, dayDate, language) => {
    const month = dayDate.getMonth();
    const dayOfWeek = getDayOfWeek(dayDate.getDay(), language);
    
    // Get same month from last year (broader range for better average)
    const lastYearStart = new Date(dayDate.getFullYear() - 1, month, 1);
    const lastYearEnd = new Date(dayDate.getFullYear() - 1, month + 1, 0);
    
    const startDateStr = lastYearStart.toISOString().split('T')[0];
    const endDateStr = lastYearEnd.toISOString().split('T')[0];

    try {
        const historicalData = await getHistoricalWeatherData(lat, lon, startDateStr, endDateStr, language);
        
        return {
            date: dayDate.toISOString().split('T')[0],
            dayOfWeek: dayOfWeek,
            temperature: historicalData.averageTemp,
            condition: "weather_historical_monthly_average",
            conditionCode: historicalData.conditionCode,
            icon: mapWeatherCodeToIcon(0), // Use default icon for averages
            dataSource: 'historical'
        };
    } catch (error) {
        console.warn(`Unable to fetch monthly average for ${dayDate.toISOString().split('T')[0]}, using default`);
        return {
            date: dayDate.toISOString().split('T')[0],
            dayOfWeek: dayOfWeek,
            temperature: 20,
            condition: "weather_historical_monthly_average",
            conditionCode: "clouds",
            icon: "02d",
            dataSource: 'historical'
        };
    }
};

/**
 * Fetches historical weather data from the Open-Meteo API.
 */
const getHistoricalWeatherData = async (lat, lon, startDate, endDate, lang = 'en') => {
    const HISTORICAL_URL = 'https://archive-api.open-meteo.com/v1/archive';
    const language = lang.startsWith('zh') ? 'zh' : 'en';

    try {
        const response = await axios.get(HISTORICAL_URL, {
            params: {
                latitude: lat,
                longitude: lon,
                start_date: startDate,
                end_date: endDate,
                daily: 'weathercode,temperature_2m_mean,temperature_2m_max,temperature_2m_min',
                timezone: 'auto'
            }
        });

        const daily = response.data.daily;
        if (!daily || daily.time.length === 0) {
            throw new Error('No historical weather data available.');
        }

        const totalTemp = daily.temperature_2m_mean.reduce((sum, temp) => sum + temp, 0);
        const averageTemp = Math.round(totalTemp / daily.temperature_2m_mean.length);
        
        // 计算温度范围
        const maxTemp = Math.round(Math.max(...daily.temperature_2m_max));
        const minTemp = Math.round(Math.min(...daily.temperature_2m_min));
        const tempRange = `${minTemp}°C - ${maxTemp}°C`;

        const conditionCounts = daily.weathercode.reduce((counts, code) => {
            counts[code] = (counts[code] || 0) + 1;
            return counts;
        }, {});
        
        const dominantCode = Object.keys(conditionCounts).reduce((a, b) => conditionCounts[a] > conditionCounts[b] ? a : b);

        // 生成天气提醒
        const weatherAlerts = generateWeatherAlerts(daily.weathercode, language);

        // 构造 dailyWeather 数组
        const dailyWeather = daily.time.map((date, idx) => ({
            date: date.split('T')[0],
            dayOfWeek: getDayOfWeek(new Date(date).getDay(), language),
            temperature: Math.round(daily.temperature_2m_mean[idx]),
            condition: getWeatherConditionFromCode(daily.weathercode[idx], language),
            conditionCode: mapWeatherCodeToCondition(daily.weathercode[idx]),
            icon: mapWeatherCodeToIcon(daily.weathercode[idx])
        }));

        return {
            averageTemp,
            tempRange,
            maxTemp,
            minTemp,
            condition: getWeatherConditionFromCode(dominantCode, language),
            conditionCode: mapWeatherCodeToCondition(dominantCode),
            weatherAlerts,
            dailyWeather
        };

    } catch (error) {
        console.error("Error fetching historical weather data:", error.message);
        throw error; // Rethrow to be caught by the main try-catch block
    }
};

// Helper functions to interpret Open-Meteo weather codes
function getWeatherConditionFromCode(code, lang = 'en') {
    const codes_zh = {
        0: '晴', 1: '基本晴朗', 2: '部分多云', 3: '阴天',
        45: '雾', 48: '冻雾',
        51: '小毛毛雨', 53: '中等毛毛雨', 55: '大毛毛雨',
        56: '冰冻毛毛雨', 57: '浓密冰冻毛毛雨',
        61: '小雨', 63: '中雨', 65: '大雨',
        66: '冻雨', 67: '大冻雨',
        71: '小雪', 73: '中雪', 75: '大雪',
        77: '雪粒',
        80: '小阵雨', 81: '中阵雨', 82: '大阵雨',
        85: '小雪阵', 86: '大雪阵',
        95: '雷暴', 96: '带小冰雹的雷暴', 99: '带大冰雹的雷暴'
    };
    const codes_en = {
        0: 'Clear', 1: 'Mainly Clear', 2: 'Partly Cloudy', 3: 'Overcast',
        45: 'Fog', 48: 'Freezing Fog',
        51: 'Light Drizzle', 53: 'Moderate Drizzle', 55: 'Dense Drizzle',
        56: 'Light Freezing Drizzle', 57: 'Dense Freezing Drizzle',
        61: 'Slight Rain', 63: 'Moderate Rain', 65: 'Heavy Rain',
        66: 'Light Freezing Rain', 67: 'Heavy Freezing Rain',
        71: 'Slight Snow', 73: 'Moderate Snow', 75: 'Heavy Snow',
        77: 'Snow Grains',
        80: 'Slight Rain Showers', 81: 'Moderate Rain Showers', 82: 'Violent Rain Showers',
        85: 'Slight Snow Showers', 86: 'Heavy Snow Showers',
        95: 'Thunderstorm', 96: 'Thunderstorm with Light Hail', 99: 'Thunderstorm with Heavy Hail'
    };
    const codes = lang === 'zh' ? codes_zh : codes_en;
    return codes[code] || (lang === 'zh' ? '未知天气' : 'Unknown');
}

function mapWeatherCodeToCondition(code) {
    if ([0, 1].includes(code)) return 'clear';
    if ([2, 3].includes(code)) return 'clouds';
    if (code >= 51 && code <= 67) return 'rain';
    if (code >= 71 && code <= 77) return 'snow';
    if (code >= 80 && code <= 99) return 'rain'; // Treat showers/thunderstorms as rain
    if ([45, 48].includes(code)) return 'special'; // Fog
    return 'any';
}

function mapWeatherCodeToIcon(code) {
    if (code >= 0 && code <= 1) return '01d'; // Clear
    if (code >= 2 && code <= 3) return '03d'; // Clouds
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return '09d'; // Rain
    if (code >= 71 && code <= 77 || (code >= 85 && code <= 86)) return '13d'; // Snow
    if (code >= 95 && code <= 99) return '11d'; // Thunderstorm
    if (code >= 45 && code <= 48) return '50d'; // Fog
    return '01d'; // Default
}

// Helper function to get day of week in Chinese
function getDayOfWeek(dayIndex, lang = 'en') {
    const days_zh = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const days_en = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const days = lang === 'zh' ? days_zh : days_en;
    return days[dayIndex];
}

// Generate mock daily weather for fallback
function generateMockDailyWeather(startDate, endDate) {
    const start = new Date(startDate);
    const end = new Date(endDate);
    const days = [];
    
    for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
        const dateStr = d.toISOString().split('T')[0];
        const dayOfWeek = getDayOfWeek(d.getDay());
        
        days.push({
            date: dateStr,
            dayOfWeek: dayOfWeek,
            temperature: Math.floor(Math.random() * 20) + 10, // 10-30°C
            condition: "多云",
            conditionCode: "clouds",
            icon: "02d",
            dataSource: 'mock'
        });
    }
    
    return days;
}

// Helper function to get months spanned by a trip
function getMonthsInTrip(startDate, endDate) {
    const months = [];
    const current = new Date(startDate);
    
    while (current <= endDate) {
        const monthIndex = current.getMonth();
        const year = current.getFullYear();
        const monthName = getMonthName(monthIndex);
        
        // Check if this month is already added
        if (!months.find(m => m.month === monthIndex && m.year === year)) {
            months.push({
                month: monthIndex,
                year: year,
                name: monthName
            });
        }
        
        // Move to next month
        current.setMonth(current.getMonth() + 1, 1);
    }
    
    return months;
}

// Helper function to get month name
function getMonthName(monthIndex) {
    const months = [
        '1月', '2月', '3月', '4月', '5月', '6月',
        '7月', '8月', '9月', '10月', '11月', '12月'
    ];
    return months[monthIndex];
}

// Get monthly average data for a specific month
async function getMonthlyAverageData(lat, lon, month, language) {
    const startDate = new Date(month.year - 1, month.month, 1);
    const endDate = new Date(month.year - 1, month.month + 1, 0);
    
    const startDateStr = startDate.toISOString().split('T')[0];
    const endDateStr = endDate.toISOString().split('T')[0];
    
    try {
        const historicalData = await getHistoricalWeatherData(lat, lon, startDateStr, endDateStr, language);
        
        return {
            monthName: month.name,
            temperature: historicalData.averageTemp,
            tempRange: historicalData.tempRange,
            maxTemp: historicalData.maxTemp,
            minTemp: historicalData.minTemp,
            condition: "weather_historical_monthly_average",
            conditionCode: historicalData.conditionCode,
            weatherAlerts: historicalData.weatherAlerts,
            icon: mapWeatherCodeToIcon(0) // Use default icon for monthly averages
        };
    } catch (error) {
        console.warn(`Unable to fetch monthly average for ${month.name}:`, error.message);
        return {
            monthName: month.name,
            temperature: 20,
            tempRange: "15°C - 25°C",
            maxTemp: 25,
            minTemp: 15,
            condition: "weather_historical_monthly_average",
            conditionCode: "clouds",
            weatherAlerts: [],
            icon: "02d"
        };
    }
}

// Generate weather alerts based on historical weather codes
function generateWeatherAlerts(weatherCodes, language) {
    const alerts = [];
    const isChinese = language === 'zh';
    
    // 统计各种天气情况
    const rainCodes = [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99];
    const snowCodes = [71, 73, 75, 77, 85, 86];
    const fogCodes = [45, 48];
    const stormCodes = [95, 96, 99];
    
    const rainCount = weatherCodes.filter(code => rainCodes.includes(code)).length;
    const snowCount = weatherCodes.filter(code => snowCodes.includes(code)).length;
    const fogCount = weatherCodes.filter(code => fogCodes.includes(code)).length;
    const stormCount = weatherCodes.filter(code => stormCodes.includes(code)).length;
    
    const totalDays = weatherCodes.length;
    const rainPercentage = (rainCount / totalDays) * 100;
    const snowPercentage = (snowCount / totalDays) * 100;
    const fogPercentage = (fogCount / totalDays) * 100;
    const stormPercentage = (stormCount / totalDays) * 100;
    
    // 生成提醒
    if (rainPercentage >= 30) {
        alerts.push(isChinese ? 
            `⚠️ 历史数据显示这段时间有 ${Math.round(rainPercentage)}% 的降雨概率，建议携带雨具` :
            `⚠️ Historical data shows ${Math.round(rainPercentage)}% chance of rain during this period, consider bringing rain gear`
        );
    }
    
    if (snowPercentage >= 20) {
        alerts.push(isChinese ? 
            `❄️ 历史数据显示这段时间有 ${Math.round(snowPercentage)}% 的降雪概率，注意保暖` :
            `❄️ Historical data shows ${Math.round(snowPercentage)}% chance of snow during this period, stay warm`
        );
    }
    
    if (fogPercentage >= 25) {
        alerts.push(isChinese ? 
            `🌫️ 历史数据显示这段时间有 ${Math.round(fogPercentage)}% 的雾天概率，注意能见度` :
            `🌫️ Historical data shows ${Math.round(fogPercentage)}% chance of fog during this period, watch visibility`
        );
    }
    
    if (stormPercentage >= 15) {
        alerts.push(isChinese ? 
            `⛈️ 历史数据显示这段时间有 ${Math.round(stormPercentage)}% 的雷暴概率，注意安全` :
            `⛈️ Historical data shows ${Math.round(stormPercentage)}% chance of thunderstorms during this period, stay safe`
        );
    }
    
    // 如果没有特殊天气，添加一般提醒
    if (alerts.length === 0) {
        alerts.push(isChinese ? 
            "📅 基于历史天气数据，建议查看实时天气预报" :
            "📅 Based on historical weather data, check real-time forecast"
        );
    }
    
    return alerts;
}

module.exports = {
    getWeatherData,
}; 