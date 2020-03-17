## Configuration

asp.net core 配置更新监听的功能

```c#
var configurationBuilder = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
    			//开启文件监听
                .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);

            var configurationRoot = configurationBuilder.Build();
			
			//这个配置变更只能使用一次
            //var token = configurationRoot.GetReloadToken();
            //token.RegisterChangeCallback(state => 
            //{
            //    Console.WriteLine("配置变更了");
            //}, configurationRoot);
			
			//推荐使用这种
			//入参  1：获取changeToken的方法 2：配置变更的处理逻辑
            ChangeToken.OnChange(() => configurationRoot.GetReloadToken(), () =>
              {
                  Console.WriteLine("配置变更了");
              });
```

