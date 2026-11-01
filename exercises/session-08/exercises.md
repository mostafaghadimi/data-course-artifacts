# SQL Practice 80 · Part 1

۸۰ تمرین روی دیتابیس `shop`. جواب‌ها در `solutions.sql` هست و شماره‌ی هر جواب با شماره‌ی تمرین یکیه.

## روش کار

1. تمرین رو بخونید و اول خودتون بنویسید.
2. اگه سینتکس یادتون نبود، لینک زیر همون تمرین رو باز کنید. هر صفحه‌ی W3Schools یک دکمه‌ی **Try it Yourself** داره که همون‌جا امتحان کنید.
3. جوابتون رو با «برای چک» مقایسه کنید.
4. فقط اگه گیر کردید جواب رو ببینید، و بعد خودتون از اول بنویسیدش.

## تفاوت W3Schools با PostgreSQL

مثال‌های W3Schools بیشتر برای MySQL و SQL Server هستن. دیتابیس ما PostgreSQL هست:

| W3Schools | PostgreSQL |
|---|---|
| `SELECT TOP 5 ...` | `SELECT ... LIMIT 5` |
| `ISNULL(x, 0)` یا `IFNULL(x, 0)` | `COALESCE(x, 0)` |
| `GETDATE()` یا `NOW()` | `now()` |
| `'a' + 'b'` یا `CONCAT('a', 'b')` | `'a' \|\| 'b'` یا `CONCAT('a', 'b')` |
| `YEAR(order_at)` | `EXTRACT(YEAR FROM order_at)` |
| `SELECT ... INTO new_table` | `CREATE TABLE new_table AS SELECT ...` |

برای چیزهایی که W3Schools صفحه نداره (تابع‌های متنی و تاریخ PostgreSQL، INTERSECT و EXCEPT، CTE و Window Function)، لینک مستندات PostgreSQL گذاشته شده.

---

## A. SELECT و مرتب‌سازی

### 1. نگاه اول به جدول
همه‌ی ستون‌های ۱۰ ردیف اول جدول `products`.
- سینتکس: [SELECT](https://www.w3schools.com/sql/sql_select.asp) · [TOP / LIMIT](https://www.w3schools.com/sql/sql_top.asp)
- برای چک: ۱۰ ردیف.

### 2. فقط ستون‌های لازم
اسم، دسته و قیمت همه‌ی محصولات.
- سینتکس: [SELECT](https://www.w3schools.com/sql/sql_select.asp)
- برای چک: ۶۰ ردیف.

### 3. بدون تکرار
فهرست دسته‌های محصول، بدون تکرار.
- سینتکس: [SELECT DISTINCT](https://www.w3schools.com/sql/sql_distinct.asp)
- برای چک: ۶ دسته.

### 4. کشورها
فهرست کشورهای مشتری‌ها، بدون تکرار و به ترتیب الفبا.
- سینتکس: [SELECT DISTINCT](https://www.w3schools.com/sql/sql_distinct.asp) · [ORDER BY](https://www.w3schools.com/sql/sql_orderby.asp)
- برای چک: ۵ ردیف. یکی خالیه؛ چرا؟

### 5. گرون‌ترین‌ها
پنج محصول گرون‌تر، از گرون به ارزون.
- سینتکس: [ORDER BY](https://www.w3schools.com/sql/sql_orderby.asp) · [TOP / LIMIT](https://www.w3schools.com/sql/sql_top.asp)
- برای چک: اولی Power Bank با 168.92.

### 6. ستون محاسبه‌ای
اسم محصول با عنوان `product`، قیمت، و قیمت با ۹٪ مالیات با عنوان `price_with_tax`، گرد شده تا دو رقم اعشار.
- سینتکس: [Aliases](https://www.w3schools.com/sql/sql_alias.asp) · [Operators](https://www.w3schools.com/sql/sql_operators.asp)
- برای چک: Headphones برابر 171.69.

### 7. مرتب‌سازی چندسطحی
مشتری‌ها به ترتیب کشور، بعد شهر، بعد اسم.
- سینتکس: [ORDER BY](https://www.w3schools.com/sql/sql_orderby.asp)
- برای چک: ردیف اول Canada, Toronto, Ali Ahmadi.

### 8. جدیدترین سفارش‌ها
پنج سفارش آخر با شماره‌ی سفارش، شماره‌ی مشتری، تاریخ و مبلغ.
- سینتکس: [ORDER BY](https://www.w3schools.com/sql/sql_orderby.asp) · [TOP / LIMIT](https://www.w3schools.com/sql/sql_top.asp)
- برای چک: اولی سفارش 777. به ساعتش دقت کنید.

### 9. صفحه‌ی دوم
محصولات رو از ارزون به گرون مرتب کنید و «صفحه‌ی دوم» رو نشون بدید، اگه هر صفحه ۱۰ محصول داشته باشه (ردیف ۱۱ تا ۲۰).
- سینتکس: [TOP / LIMIT](https://www.w3schools.com/sql/sql_top.asp) · در PostgreSQL: [LIMIT و OFFSET](https://www.postgresql.org/docs/16/queries-limit.html)
- برای چک: اولین ردیف Mask Pack با 17.07.

### 10. ترکیب‌های یکتا
همه‌ی ترکیب‌های یکتای کشور و شهر مشتری‌ها.
- سینتکس: [SELECT DISTINCT](https://www.w3schools.com/sql/sql_distinct.asp)
- برای چک: ۲۱ ردیف.

## B. فیلتر کردن

### 11. سفارش‌های لغوشده
چند سفارش با وضعیت `cancelled` داریم؟
- سینتکس: [WHERE](https://www.w3schools.com/sql/sql_where.asp) · [COUNT](https://www.w3schools.com/sql/sql_count.asp)
- برای چک: 4026.

### 12. کتاب‌های ارزون
کتاب‌هایی (دسته‌ی `Books`) با قیمت کمتر از 15.
- سینتکس: [AND](https://www.w3schools.com/sql/sql_and.asp)
- برای چک: ۲ محصول.

### 13. دو شهر
چند مشتری در Shiraz یا Tabriz زندگی می‌کنن؟ یک بار با `OR` و یک بار با `IN`.
- سینتکس: [OR](https://www.w3schools.com/sql/sql_or.asp) · [IN](https://www.w3schools.com/sql/sql_in.asp)
- برای چک: 873.

### 14. نه این، نه اون
چند سفارش وضعیتشون نه `paid` هست نه `refunded`؟
- سینتکس: [NOT](https://www.w3schools.com/sql/sql_not.asp) · [IN](https://www.w3schools.com/sql/sql_in.asp)
- برای چک: 7528.

### 15. شروع ایمیل
چند مشتری ایمیلشون با `sara.` شروع می‌شه؟
- سینتکس: [LIKE](https://www.w3schools.com/sql/sql_like.asp) · [Wildcards](https://www.w3schools.com/sql/sql_wildcards.asp)
- برای چک: 278.

### 16. هر جای اسم
محصولاتی که هر جای اسمشون `Set` اومده.
- سینتکس: [LIKE](https://www.w3schools.com/sql/sql_like.asp) · [Wildcards](https://www.w3schools.com/sql/sql_wildcards.asp)
- برای چک: ۵ محصول.

### 17. دقیقاً چهار حرف
محصولاتی که اسمشون دقیقاً چهار حرفه. راهنمایی: علامت `_` یعنی دقیقاً یک حرف.
- سینتکس: [Wildcards](https://www.w3schools.com/sql/sql_wildcards.asp)
- برای چک: ۴ محصول.

### 18. بازه‌ی مبلغ
چند سفارش مبلغشون بین 200 و 300 هست؟
- سینتکس: [BETWEEN](https://www.w3schools.com/sql/sql_between.asp)
- برای چک: 5969. آیا 200 و 300 خودشون هم حساب شدن؟

### 19. خالی و پر
چند مشتری شهرشون مشخص نیست؟ و چند مشتری هم شهر و هم کشورشون مشخصه؟
- سینتکس: [NULL Values](https://www.w3schools.com/sql/sql_null_values.asp)
- برای چک: 409 و 4457.

### 20. اهمیت پرانتز
سفارش‌هایی که وضعیتشون `paid` یا `refunded` هست **و** مبلغشون بیشتر از 500 هست. یک بار با پرانتز دور شرط `OR` و یک بار بدون پرانتز بنویسید. چرا جواب‌ها فرق دارن؟
- سینتکس: [AND](https://www.w3schools.com/sql/sql_and.asp) · [OR](https://www.w3schools.com/sql/sql_or.asp)
- برای چک: با پرانتز 1288، بدون پرانتز 39998.

## C. تابع‌ها و CASE

### 21. حروف بزرگ و طول
اسم همه‌ی محصولات با حروف بزرگ و طول اسمشون، از بلندترین به کوتاه‌ترین.
- سینتکس: در PostgreSQL: [String Functions](https://www.postgresql.org/docs/16/functions-string.html)
- برای چک: بلندترین Resistance Band با ۱۵ حرف.

### 22. چسباندن متن
برای هر محصول یک ستون `label` بسازید به شکل `Headphones (Electronics)`.
- سینتکس: [Operators](https://www.w3schools.com/sql/sql_operators.asp) · در PostgreSQL: [String Functions](https://www.postgresql.org/docs/16/functions-string.html)
- برای چک: ۶۰ ردیف، اولی `Headphones (Electronics)`.

### 23. نام کوچک
نام کوچک مشتری‌ها رو از `full_name` جدا کنید و ببینید کدوم نام بیشتر تکرار شده. راهنمایی: `SPLIT_PART`.
- سینتکس: در PostgreSQL: [String Functions](https://www.postgresql.org/docs/16/functions-string.html)
- برای چک: Babak با 283 نفر.

### 24. گرد کردن
قیمت هر محصول رو گرد شده به نزدیک‌ترین عدد صحیح، گرد شده به بالا و گرد شده به پایین نشون بدید.
- سینتکس: در PostgreSQL: [Math Functions](https://www.postgresql.org/docs/16/functions-math.html)
- برای چک: Headphones برابر 158، 158 و 157.

### 25. دسته‌بندی قیمت
محصولات رو به `cheap` (کمتر از 20)، `mid` (20 تا کمتر از 100) و `premium` (100 و بیشتر) تقسیم کنید و هر گروه رو بشمارید.
- سینتکس: [CASE](https://www.w3schools.com/sql/sql_case.asp)
- برای چک: mid 35، cheap 19، premium 6.

### 26. اندازه‌ی سفارش
سفارش‌ها رو به `small` (کمتر از 100)، `medium` (100 تا کمتر از 300) و `large` (300 و بیشتر) تقسیم کنید و هر گروه رو بشمارید.
- سینتکس: [CASE](https://www.w3schools.com/sql/sql_case.asp) · [GROUP BY](https://www.w3schools.com/sql/sql_groupby.asp)
- برای چک: small 24680، medium 19488، large 5832.

### 27. جای خالی رو پر کن
اسم مشتری‌ها و شهرشون؛ اگه شهر خالی بود بنویسید `unknown`.
- سینتکس: [NULL Functions](https://www.w3schools.com/sql/sql_isnull.asp) (در PostgreSQL از `COALESCE` استفاده کنید)
- برای چک: مشتری شماره‌ی 1 (Omid Moradi) می‌شه `unknown`.

### 28. اولین مقدار موجود
برای هر مشتری یک ستون `location` بسازید: اگه شهر داشت شهر، اگه نداشت کشور، اگه هیچ‌کدوم رو نداشت `unknown`. بعد تعداد مشتری هر `location` رو بشمارید.
- سینتکس: [NULL Functions](https://www.w3schools.com/sql/sql_isnull.asp)
- برای چک: `unknown` برای 14 مشتری.

### 29. صفرها رو حساب نکن
میانگین مبلغ همه‌ی سفارش‌ها رو یک بار عادی و یک بار بدون سفارش‌های با مبلغ صفر حساب کنید. راهنمایی: `NULLIF`.
- سینتکس: [NULL Functions](https://www.w3schools.com/sql/sql_isnull.asp) · در PostgreSQL: [NULLIF](https://www.postgresql.org/docs/16/functions-conditional.html#FUNCTIONS-NULLIF)
- برای چک: 142.22 و 144.33.

### 30. نرخ موفقیت
چند درصد سفارش‌ها `paid` هستن؟ با `CASE` به سفارش‌های paid عدد 1 و به بقیه 0 بدید و میانگین بگیرید.
- سینتکس: [CASE](https://www.w3schools.com/sql/sql_case.asp) · [AVG](https://www.w3schools.com/sql/sql_avg.asp)
- برای چک: 0.799.

## D. خلاصه کردن داده

### 31. آمار مشتری‌ها
تعداد کل مشتری‌ها، اولین و آخرین تاریخ ثبت‌نام، در یک ردیف.
- سینتکس: [COUNT](https://www.w3schools.com/sql/sql_count.asp) · [MIN و MAX](https://www.w3schools.com/sql/sql_min_max.asp)
- برای چک: 5000، از 2024-06-01 تا 2026-08-29.

### 32. فروش کل
مجموع و میانگین مبلغ سفارش‌های `paid`؛ میانگین تا دو رقم اعشار.
- سینتکس: [SUM](https://www.w3schools.com/sql/sql_sum.asp) · [AVG](https://www.w3schools.com/sql/sql_avg.asp)
- برای چک: 5770297.36 و 144.48.

### 33. آمار هر دسته
برای هر دسته، تعداد محصول و میانگین قیمت.
- سینتکس: [GROUP BY](https://www.w3schools.com/sql/sql_groupby.asp) · [Aggregate Functions](https://www.w3schools.com/sql/sql_aggregate_functions.asp)
- برای چک: Electronics برابر 116.60.

### 34. سفارش‌ها به تفکیک وضعیت
تعداد سفارش در هر وضعیت، از بیشتر به کمتر.
- سینتکس: [GROUP BY](https://www.w3schools.com/sql/sql_groupby.asp)
- برای چک: paid با 39938 اوله.

### 35. شهرهای پرجمعیت
شهرهایی که بیشتر از 400 مشتری دارن.
- سینتکس: [HAVING](https://www.w3schools.com/sql/sql_having.asp)
- برای چک: ۹ ردیف، Tehran با 1408 اوله. یکی از ردیف‌ها اسم شهر نداره؛ چرا اومده؟

### 36. مشتری‌های پرسفارش
مشتری‌هایی که بیشتر از 30 سفارش داشتن (فقط از جدول `orders`).
- سینتکس: [HAVING](https://www.w3schools.com/sql/sql_having.asp)
- برای چک: ۲۸ مشتری؛ مشتری 1 با 70 سفارش اوله.

### 37. روش‌های پرداخت
تعداد پرداخت و مجموع مبلغ برای هر روش پرداخت.
- سینتکس: [GROUP BY](https://www.w3schools.com/sql/sql_groupby.asp) · [SUM](https://www.w3schools.com/sql/sql_sum.asp)
- برای چک: `card` با 24735 پرداخت.

### 38. مشتری‌های فعال ۲۰۲۶
چند مشتری مختلف در سال ۲۰۲۶ حداقل یک سفارش داشتن؟
- سینتکس: [COUNT](https://www.w3schools.com/sql/sql_count.asp) · [SELECT DISTINCT](https://www.w3schools.com/sql/sql_distinct.asp)
- برای چک: 4234.

### 39. شمارش شرطی
برای هر روش پرداخت، در دو ستون جدا بشمارید چند پرداخت بالای 500 و چند پرداخت 500 یا کمتر بوده.
- سینتکس: [CASE](https://www.w3schools.com/sql/sql_case.asp) · [SUM](https://www.w3schools.com/sql/sql_sum.asp)
- برای چک: card با 528 و 24207.

### 40. دو شرط روی گروه
دسته‌هایی که بیشتر از ۵ محصول دارن و میانگین قیمتشون بالای 30 هست.
- سینتکس: [HAVING](https://www.w3schools.com/sql/sql_having.asp)
- برای چک: ۴ دسته.

## E. تاریخ و زمان

### 41. سفارش‌های ماهانه
تعداد سفارش در هر ماه سال ۲۰۲۶.
- سینتکس: [Dates](https://www.w3schools.com/sql/sql_dates.asp) · در PostgreSQL: [date_trunc](https://www.postgresql.org/docs/16/functions-datetime.html#FUNCTIONS-DATETIME-TRUNC)
- برای چک: ۹ ماه، ژانویه با 2267.

### 42. ثبت‌نام‌های یک ماه
چند مشتری در اوت ۲۰۲۶ ثبت‌نام کردن؟
- سینتکس: [Dates](https://www.w3schools.com/sql/sql_dates.asp)
- برای چک: 179.

### 43. سفارش هر سال
تعداد سفارش در هر سال.
- سینتکس: در PostgreSQL: [EXTRACT](https://www.postgresql.org/docs/16/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT)
- برای چک: 2025 با 15718 و 2026 با 34282.

### 44. روز هفته
تعداد سفارش در هر روز هفته. کدوم روز بیشترین سفارش رو داره؟
- سینتکس: در PostgreSQL: [TO_CHAR](https://www.postgresql.org/docs/16/functions-formatting.html)
- برای چک: Sunday با 7273.

### 45. حساب‌های قدیمی
چند مشتری بیشتر از دو سال قبل از 2026-09-30 ثبت‌نام کردن؟ با `INTERVAL` بنویسید.
- سینتکس: در PostgreSQL: [Date/Time Operators](https://www.postgresql.org/docs/16/functions-datetime.html)
- برای چک: 764.

### 46. عمر حساب کاربری
برای مشتری شماره‌ی 1، فاصله‌ی ثبت‌نام تا 2026-09-30 رو با `AGE` حساب کنید.
- سینتکس: در PostgreSQL: [AGE](https://www.postgresql.org/docs/16/functions-datetime.html)
- برای چک: 1 year 10 mons 6 days.

## F. ترکیب جدول‌ها

### 47. سفارش و مشتری
برای هر سفارش، شماره‌ی سفارش، اسم مشتری و شهرش.
- سینتکس: [INNER JOIN](https://www.w3schools.com/sql/sql_join_inner.asp)
- برای چک: 50000 ردیف.

### 48. فاکتور یک سفارش
اقلام سفارش 100: شماره‌ی ردیف، اسم محصول، تعداد، قیمت واحد و مبلغ هر ردیف.
- سینتکس: [INNER JOIN](https://www.w3schools.com/sql/sql_join_inner.asp)
- برای چک: ۲ ردیف، Monitor و Lotion.

### 49. فروش هر دسته
مجموع فروش (تعداد × قیمت واحد) هر دسته در سفارش‌های `paid`. سه جدول لازمه.
- سینتکس: [Joins](https://www.w3schools.com/sql/sql_join.asp) · [GROUP BY](https://www.w3schools.com/sql/sql_groupby.asp)
- برای چک: Electronics با 2638860.20.

### 50. همه‌ی مشتری‌ها با تعداد سفارش
همه‌ی مشتری‌ها با تعداد سفارششون؛ بی‌سفارش‌ها با صفر.
- سینتکس: [LEFT JOIN](https://www.w3schools.com/sql/sql_join_left.asp)
- برای چک: 5000 ردیف. اگه به‌جای صفر عدد 1 دیدید، فرق `COUNT(*)` و `COUNT(o.order_id)` رو بررسی کنید.

### 51. همون، با RIGHT JOIN
تمرین ۵۰ رو با `RIGHT JOIN` بنویسید و جدول `orders` رو اول بیارید.
- سینتکس: [RIGHT JOIN](https://www.w3schools.com/sql/sql_join_right.asp)
- برای چک: دقیقاً همون جواب ۵۰.

### 52. سفارش بدون کالا
چند سفارش هیچ قلم کالایی ندارن؟
- سینتکس: [LEFT JOIN](https://www.w3schools.com/sql/sql_join_left.asp) · [NULL Values](https://www.w3schools.com/sql/sql_null_values.asp)
- برای چک: 730.

### 53. سفارش بدون پرداخت
سفارش‌هایی که پرداخت ندارن، به تفکیک وضعیت.
- سینتکس: [LEFT JOIN](https://www.w3schools.com/sql/sql_join_left.asp)
- برای چک: cancelled 4026، pending 3502.

### 54. تغییر سگمنت
جدول `customer_segments` تاریخچه‌ی سگمنت هر مشتریه. با وصل کردن جدول به خودش، هر تغییر رو نشون بدید: مشتری، سگمنت قبلی، سگمنت جدید و تاریخ تغییر. راهنمایی: `valid_to` ردیف قبلی برابر `valid_from` ردیف بعدیه.
- سینتکس: [Self Join](https://www.w3schools.com/sql/sql_join_self.asp)
- برای چک: 3386 ردیف.

### 55. مقایسه‌ی دو کشور
برای هر شهر، تعداد مشتری‌های ایرانی و ترکیه‌ای کنار هم؛ شهرهایی که فقط یک طرف هستن هم بیان.
- سینتکس: [FULL JOIN](https://www.w3schools.com/sql/sql_join_full.asp)
- برای چک: ۸ ردیف. ردیف «بدون شهر» دو بار اومده؛ چرا جفت نشدن؟

### 56. فروش هر شهر
مجموع مبلغ سفارش‌های `paid` بر اساس شهر مشتری.
- سینتکس: [INNER JOIN](https://www.w3schools.com/sql/sql_join_inner.asp) · [GROUP BY](https://www.w3schools.com/sql/sql_groupby.asp)
- برای چک: Tehran با 1638288.79.

### 57. چهار جدول
مشتری‌های ساکن Istanbul از هر محصول چند عدد خریدن؟ از بیشتر به کمتر.
- سینتکس: [Joins](https://www.w3schools.com/sql/sql_join.asp)
- برای چک: Cap با 315 عدد.

### 58. همه‌ی ترکیب‌ها
همه‌ی ترکیب‌های ممکن «دسته‌ی محصول» و «روش پرداخت».
- سینتکس: در PostgreSQL: [CROSS JOIN](https://www.postgresql.org/docs/16/queries-table-expressions.html#QUERIES-JOIN)
- برای چک: 18 ردیف (۶ × ۳).

## G. زیرکوئری، EXISTS، عملیات مجموعه‌ای و CTE

### 59. گرون‌تر از میانگین
محصولاتی که قیمتشون از میانگین قیمت همه‌ی محصولات بیشتره.
- سینتکس: [Operators](https://www.w3schools.com/sql/sql_operators.asp) (زیرکوئری داخل WHERE)
- برای چک: ۲۰ محصول.

### 60. خریدهای بزرگ
مشتری‌هایی که حداقل یک سفارش بالای 1000 داشتن. با `IN` و زیرکوئری بنویسید.
- سینتکس: [IN](https://www.w3schools.com/sql/sql_in.asp)
- برای چک: ۱۰ مشتری.

### 61. مشتری‌های با مرجوعی
چند مشتری حداقل یک سفارش `refunded` داشتن؟ با `EXISTS`.
- سینتکس: [EXISTS](https://www.w3schools.com/sql/sql_exists.asp)
- برای چک: 1880.

### 62. هرگز خرید نکرده
چند مشتری هیچ‌وقت سفارش ندادن؟ با `NOT EXISTS`.
- سینتکس: [EXISTS](https://www.w3schools.com/sql/sql_exists.asp)
- برای چک: 750.

### 63. UNION یا UNION ALL
شهرهای مشتری‌های ایرانی و ترکیه‌ای رو یک بار با `UNION` و یک بار با `UNION ALL` زیر هم بذارید و تعداد ردیف‌ها رو مقایسه کنید.
- سینتکس: [UNION](https://www.w3schools.com/sql/sql_union.asp) · [UNION ALL](https://www.w3schools.com/sql/sql_union_all.asp)
- برای چک: ۷ و 3870.

### 64. ANY یا ALL
چند محصول دسته‌ی `Home` از **حداقل یکی** از محصولات `Fashion` گرون‌ترن؟ چندتا از **همه‌ی** محصولات `Fashion` گرون‌ترن؟
- سینتکس: [ANY](https://www.w3schools.com/sql/sql_any_all.asp) · [ALL](https://www.w3schools.com/sql/sql_all.asp)
- برای چک: 10 و 3.

### 65. هم این، هم اون
چند مشتری هم سفارش `refunded` داشتن و هم سفارش `cancelled`؟ با `INTERSECT`.
- سینتکس: در PostgreSQL: [UNION، INTERSECT، EXCEPT](https://www.postgresql.org/docs/16/queries-union.html)
- برای چک: 1140.

### 66. این، منهای اون
تمرین ۶۲ رو این بار با `EXCEPT` بنویسید.
- سینتکس: در PostgreSQL: [UNION، INTERSECT، EXCEPT](https://www.postgresql.org/docs/16/queries-union.html)
- برای چک: 750.

### 67. گرون‌ترین هر دسته
گرون‌ترین محصول هر دسته. راهنمایی: زیرکوئری‌ای که به ردیف بیرونی اشاره می‌کنه.
- سینتکس: [Operators](https://www.w3schools.com/sql/sql_operators.asp) (زیرکوئری وابسته)
- برای چک: ۶ ردیف؛ برای Electronics محصول Power Bank.

### 68. زیرکوئری در FROM
به‌طور میانگین هر مشتری (از اونایی که سفارش دارن) چند سفارش داده؟ اول تعداد سفارش هر مشتری رو در یک زیرکوئری حساب کنید، بعد میانگین بگیرید.
- سینتکس: [AVG](https://www.w3schools.com/sql/sql_avg.asp) · [Aliases](https://www.w3schools.com/sql/sql_alias.asp)
- برای چک: 11.76.

### 69. ده مشتری برتر
با `WITH` اول مجموع خرید `paid` هر مشتری رو حساب کنید، بعد ده مشتری برتر رو با اسمشون نشون بدید.
- سینتکس: در PostgreSQL: [WITH Queries (CTE)](https://www.postgresql.org/docs/16/queries-with.html)
- برای چک: Omid Moradi با 9613.56.

### 70. سهم هر دسته
سهم درصدی هر دسته از کل فروش `paid` (تمرین ۴۹).
- سینتکس: [WITH Queries (CTE)](https://www.postgresql.org/docs/16/queries-with.html)
- برای چک: Electronics حدود 45.7٪.

## H. ساختن جدول، تغییر داده و تراکنش

این تمرین‌ها پشت سر هم روی جدول‌های جدید کار می‌کنن. در آخر (تمرین ۷۸) همه رو پاک می‌کنیم تا دیتابیس مثل اول بشه.

### 71. یک جدول تازه
جدول `vip_customers` رو با این ستون‌ها بسازید:
- `customer_id`: کلید اصلی، و ارجاع به `customers`
- `full_name`: متن، اجباری
- `total_spent`: عدد با دو رقم اعشار، اجباری، و نباید منفی باشه
- `added_at`: تاریخ و ساعت، با مقدار پیش‌فرض زمان فعلی

- سینتکس: [CREATE TABLE](https://www.w3schools.com/sql/sql_create_table.asp) · [Constraints](https://www.w3schools.com/sql/sql_constraints.asp) · [PRIMARY KEY](https://www.w3schools.com/sql/sql_primarykey.asp) · [FOREIGN KEY](https://www.w3schools.com/sql/sql_foreignkey.asp) · [CHECK](https://www.w3schools.com/sql/sql_check.asp) · [DEFAULT](https://www.w3schools.com/sql/sql_default.asp)

### 72. پر کردن از یک کوئری
مشتری‌هایی که مجموع خرید `paid` اون‌ها بیشتر از 3000 هست رو با یک دستور در `vip_customers` بریزید.
- سینتکس: [INSERT INTO SELECT](https://www.w3schools.com/sql/sql_insert_into_select.asp)
- برای چک: 99 ردیف.

### 73. قانون‌ها رو امتحان کنید
چهار `INSERT` بنویسید که هر کدوم یکی از قانون‌های جدول رو بشکنه: مبلغ منفی، مشتری‌ای که وجود نداره، `customer_id` تکراری، و بدون `full_name`. هر چهارتا باید خطا بدن. متن هر خطا رو بخونید.
- سینتکس: [INSERT INTO](https://www.w3schools.com/sql/sql_insert.asp) · [Constraints](https://www.w3schools.com/sql/sql_constraints.asp) · [NOT NULL](https://www.w3schools.com/sql/sql_notnull.asp)
- برای چک: چهار خطا با این کلمه‌ها: `check constraint`، `foreign key`، `duplicate key`، `not-null`.

### 74. ستون جدید و آپدیت
ستون `tier` رو اضافه کنید. به مشتری‌هایی که بیشتر از 5000 خرید کردن `gold` و به بقیه `silver` بدید.
- سینتکس: [ALTER TABLE](https://www.w3schools.com/sql/sql_alter.asp) · [UPDATE](https://www.w3schools.com/sql/sql_update.asp)
- برای چک: gold 7، silver 92.

### 75. ویو
یک ویو به اسم `monthly_paid_revenue` بسازید که درآمد `paid` هر ماه رو نشون بده. بعد سه ماه آخر رو از روی ویو بخونید.
- سینتکس: [Views](https://www.w3schools.com/sql/sql_view.asp)
- برای چک: ویو ۲۱ ردیف داره.

### 76. کپی بخشی از جدول
یک جدول جدید به اسم `orders_sep_2026` بسازید که فقط سفارش‌های سپتامبر ۲۰۲۶ توش باشه، با یک دستور.
- سینتکس: [SELECT INTO](https://www.w3schools.com/sql/sql_select_into.asp) (در PostgreSQL: `CREATE TABLE ... AS SELECT`)
- برای چک: 6185 ردیف.

### 77. حذف و برگشت
داخل یک تراکنش، ردیف‌های `silver` جدول `vip_customers` رو حذف کنید و بشمارید. بعد `ROLLBACK` کنید و دوباره بشمارید.
- سینتکس: [DELETE](https://www.w3schools.com/sql/sql_delete.asp) · در PostgreSQL: [Transactions](https://www.postgresql.org/docs/16/tutorial-transactions.html)
- برای چک: 7، و بعد از `ROLLBACK` دوباره 99.

### 78. جمع کردن
ویو و دو جدولی که ساختید رو پاک کنید.
- سینتکس: [DROP TABLE](https://www.w3schools.com/sql/sql_drop_table.asp) · [Views](https://www.w3schools.com/sql/sql_view.asp)
- برای چک: `SELECT * FROM vip_customers;` باید خطای «جدول وجود نداره» بده.

## I. Window Function

### 79. تاریخچه‌ی خرید یک مشتری
همه‌ی سفارش‌های مشتری شماره‌ی 1 به ترتیب تاریخ، با سه ستون اضافه: شماره‌ی سفارش (اولین، دومین و …)، مبلغ سفارش قبلی، و جمع خرید تا همین سفارش.
- سینتکس: در PostgreSQL: [Window Functions](https://www.postgresql.org/docs/16/tutorial-window.html)
- برای چک: ۷۰ سفارش؛ جمع خرید در آخرین سفارش 11119.72.

### 80. اولین سفارش هر مشتری
با `ROW_NUMBER` اولین سفارش هر مشتری رو پیدا کنید و بشمارید.
- سینتکس: در PostgreSQL: [Window Functions](https://www.postgresql.org/docs/16/tutorial-window.html)
- برای چک: 4250.
