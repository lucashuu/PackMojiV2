require('dotenv').config();
const axios = require('axios');

const API_KEY = process.env.OPENWEATHER_API_KEY;
const GEOCODE_URL = 'http://api.openweathermap.org/geo/1.0/direct';
const WEATHER_URL = 'https://api.openweathermap.org/data/3.0/onecall';

/**
 * Fetches real weather data for a given destination and date range.
 * 1. Geocodes the destination name to get latitude and longitude.
 * 2. Fetches the 8-day daily forecast for those coordinates.
 * 3. Returns daily weather information for each day of the trip.
 */
const getWeatherData = async (destination, startDate, endDate, lang = 'en') => {
    if (!API_KEY) {
        throw new Error('OpenWeather API key is not configured. Please set OPENWEATHER_API_KEY in .env file.');
    }
    console.log(`Fetching real weather for ${destination}...`);

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

        // 2. Fetch 8-day forecast
        const weatherResponse = await axios.get(WEATHER_URL, {
            params: { lat, lon, exclude: 'current,minutely,hourly,alerts', appid: API_KEY, units: 'metric', lang: language }
        });

        if (!weatherResponse.data || !weatherResponse.data.daily) {
            throw new Error('Invalid weather data received from API.');
        }

        const tripStart = new Date(startDate);
        const tripEnd = new Date(endDate);
        const duration = Math.round((tripEnd - tripStart) / (1000 * 60 * 60 * 24)) + 1;

        // 3. Filter available forecasts to get days within the trip dates
        const forecastedDays = weatherResponse.data.daily.map(day => {
            const date = new Date(day.dt * 1000);
            return {
                date: date.toISOString().split('T')[0],
                dayOfWeek: getDayOfWeek(date.getDay(), language),
                temperature: Math.round(day.temp.day),
                condition: day.weather[0].description,
                conditionCode: day.weather[0].main.toLowerCase(),
                icon: day.weather[0].icon
            };
        }).filter(day => {
            const dayDate = new Date(day.date);
            // Use setHours to avoid timezone issues affecting date comparison
            return dayDate.setHours(0,0,0,0) >= tripStart.setHours(0,0,0,0) && dayDate.setHours(0,0,0,0) <= tripEnd.setHours(0,0,0,0);
        });

        // 4. Case 1: Trip is entirely in the future (no forecast days)
        if (forecastedDays.length === 0) {
            console.warn(`No real-time forecast available. Fetching historical data for summary.`);
            const lastYearStartDate = new Date(tripStart);
            lastYearStartDate.setFullYear(lastYearStartDate.getFullYear() - 1);
            const lastYearEndDate = new Date(tripEnd);
            lastYearEndDate.setFullYear(lastYearEndDate.getFullYear() - 1);

            const historicalData = await getHistoricalWeatherData(
                lat,
                lon,
                lastYearStartDate.toISOString().split('T')[0],
                lastYearEndDate.toISOString().split('T')[0],
                language
            );

            return {
                averageTemp: historicalData.averageTemp,
                condition: `历史平均: ${historicalData.condition}`,
                conditionCode: historicalData.conditionCode,
                dailyWeather: historicalData.dailyWeather, // Return historical daily data
                isHistorical: true
            };
        }

        // 5. Case 2: Trip is fully or partially in the forecast window
        const totalTemp = forecastedDays.reduce((sum, day) => sum + day.temperature, 0);
        const averageTemp = Math.round(totalTemp / forecastedDays.length);

        const conditionCounts = forecastedDays.reduce((counts, day) => {
            counts[day.conditionCode] = (counts[day.conditionCode] || 0) + 1;
            return counts;
        }, {});
        const dominantConditionCode = Object.keys(conditionCounts).reduce((a, b) => conditionCounts[a] > conditionCounts[b] ? a : b);
        const dominantCondition = forecastedDays.find(d => d.conditionCode === dominantConditionCode).condition;

        const isPartialForecast = forecastedDays.length < duration;

        return {
            averageTemp,
            condition: dominantCondition,
            conditionCode: dominantConditionCode,
            dailyWeather: forecastedDays, // Only return available forecast days
            isHistorical: isPartialForecast
        };

    } catch (error) {
        console.error("Error fetching weather data:", error.response ? error.response.data : error.message);
        // Fallback to mock data in case of any error
        return {
            averageTemp: 15,
            condition: "多云",
            conditionCode: "clouds",
            dailyWeather: generateMockDailyWeather(startDate, endDate),
            isHistorical: false
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
                daily: 'weathercode,temperature_2m_mean',
                timezone: 'auto'
            }
        });

        const daily = response.data.daily;
        if (!daily || daily.time.length === 0) {
            throw new Error('No historical weather data available.');
        }

        const totalTemp = daily.temperature_2m_mean.reduce((sum, temp) => sum + temp, 0);
        const averageTemp = Math.round(totalTemp / daily.temperature_2m_mean.length);

        const conditionCounts = daily.weathercode.reduce((counts, code) => {
            counts[code] = (counts[code] || 0) + 1;
            return counts;
        }, {});
        
        const dominantCode = Object.keys(conditionCounts).reduce((a, b) => conditionCounts[a] > conditionCounts[b] ? a : b);

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
            condition: getWeatherConditionFromCode(dominantCode, language),
            conditionCode: mapWeatherCodeToCondition(dominantCode),
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
            icon: "02d"
        });
    }
    
    return days;
}

module.exports = {
    getWeatherData,
}; 