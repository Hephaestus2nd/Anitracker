export const apiLinks = Object.freeze({
    ANILIST_API: "https://graphql.anilist.co",
    API_ANIME: "/api/anime"
})

export const apiQueries = Object.freeze({
    ANILIST_SEARCH_BY_TITLE: `
query ($search: String!) {
  Page {
    media(search: $search, type: ANIME) {
      idMal
      title {
        english
        romaji
      }
      episodes
			coverImage {
				extraLarge
			}
			bannerImage
      description
    }
  }
}`


})

