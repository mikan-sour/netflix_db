import pandas as pd
import numpy as np
import random
import string
from random import randint

def parse_string_arr(str):
    remove_bracs = ""
    if (str[0] == "[" and str[len(str) - 1] == "]"):
        remove_bracs = str[1:-1]

    processed = [x.replace("\'", "").strip() for x in remove_bracs.split(",")]
    return processed

def random_str():
    return ''.join(random.choice(string.ascii_letters) for i in range(15))

def seed_users(x):
    return [[random_str(),random_str(),True,False] for n in range(x)]

def recersive_check_for_likes(list_of_likes):
    user_id = randint(1, 950)
    if user_id not in list_of_likes:
        list_of_likes.append(user_id)
        return user_id
    else:
        recersive_check_for_likes(list_of_likes)

def seed_likes(iterable, start_at_zero_index):
    likes = []
    for i, _ in iterable:
        already_liked = []
        for x in range(randint(1, 30)):
            like_id = recersive_check_for_likes(already_liked)
            likes.append((i if start_at_zero_index else i + 1, like_id, "DISLIKE" if x % 3 is 0 else "LIKE"))

    return likes

def process():
    # get all `titles` in the four best files
    bmby = pd.read_csv('../raw_data/best_movie_by_year_netflix.csv')['TITLE'].tolist()
    bm = pd.read_csv('../raw_data/best_movies_netflix.csv')['TITLE'].tolist()
    bsby = pd.read_csv('../raw_data/best_show_by_year_netflix.csv')['TITLE'].tolist()
    bs = pd.read_csv('../raw_data/best_shows_netflix.csv')['TITLE'].tolist()
    titles = bmby + bm + bsby + bs

    # join on raw_titles and limit to only those --- THIS IS titles.csv
    df = pd.read_csv('../raw_data/raw_titles.csv')
    df = df[df['title'].isin(titles)]
    df['production_countries'] = df['production_countries'].apply(lambda x: parse_string_arr(x))

    df = df.reset_index(drop=True)
    df.index += 1

    # using title_id from above join df, filter credits for matching title_id --- THIS IS credits.csv
    credits_df = pd.read_csv('../raw_data/raw_credits.csv')
    credits_df = credits_df[credits_df['id'].isin(df['id'].tolist())]
    credits_df = credits_df.drop(['index','person_id'], axis=1)
    credits_df = credits_df.rename(columns={'id': 'title_id','name':'person_id'})
    credits_df = credits_df.replace({np.nan: None})
    # people table is taken from unique `name` in credits_df
    people = credits_df['person_id'].unique()

    # change the name column value to be [index +1] for that name in `people` array
    credits_df['person_id'] = credits_df['person_id'].apply(lambda x: people.tolist().index(x) + 1)

    # change the `id` column in credits_df to the row number of the matching id in df for titles (gives us title_id)
    credits_df['title_id'] = credits_df['title_id'].apply(lambda x: df[df['id'] == f'{x}'].index[0])

    # countries
    countries_df = pd.read_csv('../raw_data/countries_raw.csv')
    countries_df = countries_df.drop([
        'alpha-3', 'country-code','iso_3166-2',
        'intermediate-region','region-code','sub-region-code',
        'intermediate-region-code'], axis=1)

    unique_countries = df['production_countries'].explode('production_countries').unique()
    sub_df_countries = df[['id', 'production_countries']].explode('production_countries')

    # id to index
    sub_df_countries['id'] = sub_df_countries['id'].apply(lambda x: df.index[df['id'] == f'{x}'.format()].tolist()[0])
    sub_df_countries['production_countries'] = sub_df_countries['production_countries'].apply(lambda x: unique_countries.tolist().index(x))

    # genres
    df['genres'] = df['genres'].apply(lambda x: parse_string_arr(x))
    unique_genres = df['genres'].explode().unique().tolist()
    sub_df_genres = df[['id','genres']].explode('genres')
    sub_df_genres['id'] = sub_df_genres['id'].apply(lambda x: df.index[df['id'] == f'{x}'.format()].tolist()[0])
    sub_df_genres['genres'] = sub_df_genres['genres'].apply(
        lambda x: unique_genres.index(x) +1)

    people_likes = seed_likes(enumerate(people.tolist()),False)

    title_likes = seed_likes(df.iterrows(),True)

    titles_df = df.drop([
        'index','id','genres',
        'production_countries'
    ], axis=1)
    titles_df = titles_df.replace({np.nan: None})
    titles_df = titles_df.rename(columns={'age_certification': 'mpa_rating'})
    titles_df['mpa_rating'] = titles_df['mpa_rating'].str.replace('-', '_')
    titles_df['mpa_rating'] = titles_df['mpa_rating'].fillna('NOT_RATED')
    titles_df['imdb_votes'] = titles_df['imdb_votes'].fillna(0)
    titles_df['imdb_votes'] = titles_df['imdb_votes'].astype(int)

    # countries
    countries_df.to_csv('../processed_data/countries.csv', index=False)

    # credits
    credits_df.to_csv('../processed_data/credits.csv', index=False)

    # genres
    pd.DataFrame(unique_genres,columns=['genre']).to_csv('../processed_data/genres.csv', index=False)

    # people
    pd.DataFrame(people, columns=['name']).to_csv('../processed_data/people.csv', index=False)

    # people_likes
    people_likes_df = pd.DataFrame(people_likes, columns=["person_id","user_id", "reaction"])
    people_likes_df.replace([np.inf, -np.inf], np.nan, inplace=True)
    people_likes_df.dropna(inplace=True)
    people_likes_df['user_id'] = people_likes_df['user_id'].astype(int)
    people_likes_df.to_csv('../processed_data/people_likes.csv', index=False)

    # title
    titles_df.to_csv('../processed_data/titles.csv', index=False)

    # title countries
    sub_df_countries.to_csv('../processed_data/titles_countries.csv', index=False)

    # title genres
    sub_df_genres.to_csv('../processed_data/titles_genres.csv', index=False)

    # titles likes
    title_likes_df = pd.DataFrame(title_likes, columns=["title_id","user_id", "reaction"])
    title_likes_df.replace([np.inf, -np.inf], np.nan, inplace=True)
    title_likes_df.dropna(inplace=True)
    title_likes_df['user_id'] = title_likes_df['user_id'].astype(int)
    title_likes_df.to_csv('../processed_data/titles_likes.csv', index=False)

    # users
    users = [["system","admin",True,True]]
    pd.DataFrame(users + seed_users(1009),
        columns=['username','password','active','is_admin'])\
            .to_csv('../processed_data/users.csv', index=False)


if __name__ == "__main__":
    process()