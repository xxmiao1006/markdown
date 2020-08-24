## asp.net core 3.0 middleware

```c#
app.Use(next =>
            {
                return async context =>
                {
                    Stopwatch stopwatch = new Stopwatch();
                    stopwatch.Start();
                    await next.Invoke(context);
                    stopwatch.Stop();
                    Console.WriteLine(context.Request.Path + "cost :" + stopwatch.ElapsedMilliseconds);
                };
            });
```



asp.net core 3.0 配置跨域后配置option请求的缓存

返回结果可以用于缓存的最长时间，单位是秒。在Firefox中，上限是24小时 （即86400秒），而在Chromium 中则是10分钟（即600秒）。Chromium 同时规定了一个默认值 5 秒。
如果值为 -1，则表示禁用缓存，每一次请求都需要提供预检请求，即用OPTIONS请求进行检测（即preflight请求-options）。

```c#
            app.UseCors(builder => builder
                .AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader()
                .AllowCredentials()
                 //设置缓存
                .SetPreflightMaxAge(TimeSpan.FromSeconds(60)));
```

