epics = require("epics")


print (epics.pv("xxx:cam1:ADCoreVersion_RBV.VAL"))

print(inspect(getmetatable(epics.pv("xxx:cam1:ADCoreVersion_RBV.VAL"))))

print "Hello World!"

for I = 1, 10 do
print(I)
epics.sleep(1.0)
end
