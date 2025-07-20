const weatherService = require('../services/weather.service');
const recommendationService = require('../services/recommendation.service');
const axios = require('axios');

// Helper to geocode destination to get country code
const getCountryCodeForDestination = async (destination) => {
    try {
        const response = await axios.get(`http://api.openweathermap.org/geo/1.0/direct`, {
            params: {
                q: destination,
                limit: 1,
                appid: process.env.OPENWEATHER_API_KEY
            }
        });
        if (!response.data || response.data.length === 0) {
            return null;
        }
        return response.data[0].country;
    } catch (error) {
        console.error("Geocoding failed:", error.message);
        return null;
    }
};

// @desc    Generate a new packing checklist
const generateChecklist = async (req, res) => {
    try {
        const { destination, startDate, endDate, activities, originCountry } = req.body;
        const lang = req.headers['accept-language'] || 'en';

        if (!destination || !startDate || !endDate || !activities || !originCountry) {
            return res.status(400).json({ 
                msg: lang.startsWith('zh') ? '请提供所有必需的信息' : 'Please provide all required fields',
                details: {
                    destination: !destination,
                    startDate: !startDate,
                    endDate: !endDate,
                    activities: !activities,
                    originCountry: !originCountry
                }
            });
        }
        
        // Validate destination by attempting to geocode it
        const weatherData = await weatherService.getWeatherData(destination, startDate, endDate, lang);
        if (!weatherData) {
            return res.status(400).json({ 
                msg: lang.startsWith('zh') ? '无法找到该目的地，请检查拼写是否正确' : 'Could not find the specified destination. Please check the spelling.'
            });
        }

        // Determine trip type (domestic vs. international)
        const destinationCountry = await getCountryCodeForDestination(destination);
        if (!destinationCountry) {
            return res.status(400).json({ 
                msg: lang.startsWith('zh') ? '无法找到该目的地，请检查拼写是否正确' : `Could not determine the country for destination: ${destination}`
            });
        }

        const tripType = (originCountry.toUpperCase() === destinationCountry.toUpperCase()) ? 'domestic' : 'international';
        console.log(`Trip Type determined: ${originCountry} to ${destinationCountry} is ${tripType}`);

        const duration = Math.ceil((new Date(endDate) - new Date(startDate)) / (1000 * 60 * 60 * 24)) + 1;
        
        // Prepare the trip context
        const tripContext = {
            durationDays: duration,
            avgTemp: weatherData.averageTemp,
            weatherCode: weatherData.conditionCode,
            activities: activities,
            lang: lang,
            tripType: tripType,
            originCountry: originCountry.toUpperCase(),
            destination: destination
        };

        // Get recommended items
        const recommendedItems = recommendationService.getRecommendedItems(tripContext);

        // Convert grouped items to the expected format
        const checklist = recommendedItems.map(group => ({
            category: group.group,
            items: group.items.map(item => ({
                id: item.id,
                name: item.name,
                emoji: item.emoji,
                quantity: item.quantity,
                category: group.group,
                note: item.note || null,
                url: item.url || null
            }))
        }));

        // Format the final response
        const response = {
            tripInfo: {
                destinationName: destination,
                durationDays: duration,
                weatherSummary: `${weatherData.condition}, ${weatherData.averageTemp}°C`,
                dailyWeather: weatherData.dailyWeather || [],
                isHistorical: weatherData.isHistorical || false,
                isMixedData: weatherData.isMixedData ?? false,
                forecastDays: weatherData.forecastDays ?? 0,
                historicalDays: weatherData.historicalDays ?? 0,
                monthlyAverages: weatherData.monthlyAverages || []
            },
            categories: checklist,
        };

        res.status(200).json(response);

    } catch (error) {
        console.error("Server Error:", error.message);
        res.status(500).json({ 
            msg: lang.startsWith('zh') ? '服务器错误，请稍后重试' : 'Server Error',
            error: error.message 
        });
    }
};

module.exports = {
    generateChecklist,
}; 