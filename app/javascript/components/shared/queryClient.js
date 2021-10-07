import { QueryClient } from 'react-query';
import { isNumeric } from '@utils';
import { matchSorter } from 'match-sorter';

const { api_geo_url, api_adresse_url, api_education_url } =
  gon.autocomplete || {};

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      queryFn: defaultQueryFn
    }
  }
});

// Avoid hiding similar matches for precise queries (like "Sainte Marie")
export function searchResultsLimit(term) {
  return term.length > 5 ? 10 : 5;
}

function buildURL(scope, term) {
  term = encodeURIComponent(term.replace(/\(|\)/g, ''));
  if (scope === 'adresse') {
    return `${api_adresse_url}/search?q=${term}&limit=5`;
  } else if (scope === 'annuaire-education') {
    return `${api_education_url}/search?dataset=fr-en-annuaire-education&q=${term}&rows=5`;
  } else if (scope === 'communes') {
    if (isNumeric(term)) {
      return `${api_geo_url}/communes?codePostal=${term}&limit=5`;
    }
    const limit = searchResultsLimit(term);
    return `${api_geo_url}/communes?nom=${term}&boost=population&limit=${limit}`;
  } else if (isNumeric(term)) {
    const code = term.padStart(2, '0');
    return `${api_geo_url}/${scope}?code=${code}&limit=5`;
  }
  return `${api_geo_url}/${scope}?nom=${term}&limit=5`;
}

function buildOptions() {
  if (window.AbortController) {
    const controller = new AbortController();
    const signal = controller.signal;
    return [{ signal }, controller];
  }
  return [{}, null];
}

async function defaultQueryFn({ queryKey: [scope, term] }) {
  if (scope == 'pays') {
    return matchSorter(await getPays(), term, { keys: ['nom'] });
  }

  const url = buildURL(scope, term);
  const [options, controller] = buildOptions();
  const promise = fetch(url, options).then((response) => {
    if (response.ok) {
      return response.json();
    }
    throw new Error(`Error fetching from "${scope}" API`);
  });
  promise.cancel = () => controller && controller.abort();
  return promise;
}

let paysCache;
async function getPays() {
  if (!paysCache) {
    paysCache = await fetch('/pays.json').then((response) => response.json());
  }
  return paysCache;
}
