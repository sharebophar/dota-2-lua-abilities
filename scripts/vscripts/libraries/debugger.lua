for key, value in pairs(package.loaders) do
    print("package.loaders", key, value)
end
print("loadDLL", loadDLL)
print("loadCRoot", loadCRoot)
print("io", io)
print("os", os)
if loadDLL and loadCRoot then
    package.loaders[3] = loadDLL
    package.loaders[4] = loadCRoot

    require("libraries.LuaPanda").start("127.0.0.1", 8818)
end
