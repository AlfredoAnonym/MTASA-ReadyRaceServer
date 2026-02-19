function pool()
    water = createWater (2118.5, -2126.4, 12, 2241, -2126.4, 12, 2118.5, -2005.7, 12, 2241, -2005.7, 12)
end
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), pool)