import urllib.request
import json
import time

# The MyAnimeList IDs for the anime you want in your database
anime_ids = [52991, 40748, 11061, 9253] # Frieren, JJK, HxH, Steins;Gate

sql_statements = []
sql_statements.append("-- Auto-generated seed data from Jikan API\n")
sql_statements.append("INSERT INTO my_anime (mal_id, title, total_episodes, cover_image_url, synopsis) VALUES")

values_list = []

print("Fetching data from Jikan API...")
for mal_id in anime_ids:
    url = f"https://api.jikan.moe/v4/anime/{mal_id}"
    
    # Fetch the JSON data
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())['data']
        
        # Extract the fields we care about
        title = data['title'].replace("'", "''") # Escape single quotes for SQL
        episodes = data['episodes'] or 0
        image_url = data['images']['jpg']['large_image_url']
        synopsis = data['synopsis'].replace("'", "''")
        
        # Format as a SQL tuple
        values_list.append(f"({mal_id}, '{title}', {episodes}, '{image_url}', '{synopsis}')")
        print(f"Downloaded: {title}")
        
    # Jikan allows 3 requests per second; sleeping ensures we don't hit rate limits
    time.sleep(1)

# Join all the values with commas and cap it with a semicolon
sql_statements.append(",\n".join(values_list) + ";")

# Write it to a file in your repository
with open("seed_data.sql", "w", encoding="utf-8") as f:
    f.write("\n".join(sql_statements))

print("Successfully generated seed_data.sql!")