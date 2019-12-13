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

