version 16.0

mata:

real scalar fesim_network_schema_version()
{
    return(1)
}

string rowvector fesim_network_diagnostic_names()
{
    return(("components", "edges", "employed_observations", ///
        "workers", "firms", "largest_component_id", ///
        "largest_edges", "largest_observations", ///
        "largest_workers", "largest_firms", ///
        "largest_observation_share", "largest_worker_share", ///
        "largest_firm_share"))
}

struct fesim_network_results scalar fesim_network_analyze(
    real matrix edges,
    real scalar workers,
    real scalar firms)
{
    struct fesim_network_results scalar result
    real scalar nodes
    real scalar edge
    real scalar worker
    real scalar firm
    real scalar left
    real scalar right
    real scalar root_left
    real scalar root_right
    real scalar component
    real scalar components
    real scalar largest
    real scalar candidate
    real colvector parent
    real colvector active_worker
    real colvector active_firm
    real colvector component_edges
    real colvector component_observations
    real colvector component_workers
    real colvector component_firms
    real colvector roots

    if (workers < 1 | workers != floor(workers) | ///
        firms < 1 | firms != floor(firms)) {
        _error(3300, "network dimensions must be positive integers")
    }
    if (cols(edges) != 3) {
        _error(3300, "network edges must have worker, firm, and observation columns")
    }
    if (rows(edges) > 0) {
        if (any(missing(edges)) | any(edges :!= floor(edges)) | ///
            any(edges[, 1] :< 1) | any(edges[, 1] :> workers) | ///
            any(edges[, 2] :< 1) | any(edges[, 2] :> firms) | ///
            any(edges[, 3] :< 1)) {
            _error(3300, "network edges contain invalid identifiers or counts")
        }
        for (edge = 2; edge <= rows(edges); edge++) {
            if (edges[edge, 1] < edges[edge - 1, 1] | ///
                (edges[edge, 1] == edges[edge - 1, 1] & ///
                edges[edge, 2] <= edges[edge - 1, 2])) {
                _error(3300, "network edges must be sorted and unique")
            }
        }
    }

    result.schema_version = fesim_network_schema_version()
    result.diagnostics = J(13, 1, .)
    result.worker_component = J(workers, 1, .)
    result.firm_component = J(firms, 1, .)
    result.validated = 0
    if (rows(edges) == 0) {
        result.diagnostics[1..5] = (0 \ 0 \ 0 \ 0 \ 0)
        result.diagnostics[7..10] = (0 \ 0 \ 0 \ 0)
        result.validated = 1
        return(result)
    }

    nodes = workers + firms
    parent = 1::nodes
    active_worker = J(workers, 1, 0)
    active_firm = J(firms, 1, 0)
    for (edge = 1; edge <= rows(edges); edge++) {
        worker = edges[edge, 1]
        firm = edges[edge, 2]
        active_worker[worker] = 1
        active_firm[firm] = 1
        left = worker
        right = workers + firm
        root_left = left
        while (parent[root_left] != root_left) {
            parent[root_left] = parent[parent[root_left]]
            root_left = parent[root_left]
        }
        root_right = right
        while (parent[root_right] != root_right) {
            parent[root_right] = parent[parent[root_right]]
            root_right = parent[root_right]
        }
        if (root_left != root_right) {
            if (root_left < root_right) parent[root_right] = root_left
            else parent[root_left] = root_right
        }
    }

    for (component = 1; component <= nodes; component++) {
        root_left = component
        while (parent[root_left] != root_left) {
            parent[root_left] = parent[parent[root_left]]
            root_left = parent[root_left]
        }
        parent[component] = root_left
    }
    for (worker = 1; worker <= workers; worker++) {
        if (active_worker[worker]) result.worker_component[worker] = parent[worker]
    }
    for (firm = 1; firm <= firms; firm++) {
        if (active_firm[firm]) {
            result.firm_component[firm] = parent[workers + firm]
        }
    }

    component_edges = J(nodes, 1, 0)
    component_observations = J(nodes, 1, 0)
    component_workers = J(nodes, 1, 0)
    component_firms = J(nodes, 1, 0)
    for (edge = 1; edge <= rows(edges); edge++) {
        component = result.worker_component[edges[edge, 1]]
        component_edges[component] = component_edges[component] + 1
        component_observations[component] = ///
            component_observations[component] + edges[edge, 3]
    }
    for (worker = 1; worker <= workers; worker++) {
        if (active_worker[worker]) {
            component = result.worker_component[worker]
            component_workers[component] = component_workers[component] + 1
        }
    }
    for (firm = 1; firm <= firms; firm++) {
        if (active_firm[firm]) {
            component = result.firm_component[firm]
            component_firms[component] = component_firms[component] + 1
        }
    }

    roots = select(1::nodes, component_workers :> 0)
    components = rows(roots)
    largest = roots[1]
    for (candidate = 2; candidate <= components; candidate++) {
        component = roots[candidate]
        if (component_observations[component] > ///
            component_observations[largest] | ///
            (component_observations[component] == ///
            component_observations[largest] & ///
            component_workers[component] > component_workers[largest]) | ///
            (component_observations[component] == ///
            component_observations[largest] & ///
            component_workers[component] == component_workers[largest] & ///
            component_firms[component] > component_firms[largest]) | ///
            (component_observations[component] == ///
            component_observations[largest] & ///
            component_workers[component] == component_workers[largest] & ///
            component_firms[component] == component_firms[largest] & ///
            component < largest)) largest = component
    }

    result.diagnostics = (components \ rows(edges) \ sum(edges[, 3]) \ ///
        sum(active_worker) \ sum(active_firm) \ largest \ ///
        component_edges[largest] \ component_observations[largest] \ ///
        component_workers[largest] \ component_firms[largest] \ ///
        component_observations[largest] / sum(edges[, 3]) \ ///
        component_workers[largest] / sum(active_worker) \ ///
        component_firms[largest] / sum(active_firm))
    result.validated = 1
    return(result)
}

void fesim_network_store_from_stata(
    real scalar workers,
    real scalar firms,
    string scalar diagnostics_name,
    string scalar worker_component_name,
    string scalar firm_component_name)
{
    struct fesim_network_results scalar result
    real matrix edges

    edges = st_data(., ("workerid", "firmid", "observations"))
    result = fesim_network_analyze(edges, workers, firms)
    st_matrix(diagnostics_name, result.diagnostics)
    st_matrix(worker_component_name, result.worker_component)
    st_matrix(firm_component_name, result.firm_component)
}

void fesim_network_mark_largest(
    string scalar worker_component_name,
    real scalar largest_component,
    string scalar keep_variable)
{
    real colvector worker_id
    real colvector worker_component

    worker_id = st_data(., "workerid")
    worker_component = st_matrix(worker_component_name)
    if (any(missing(worker_id)) | any(worker_id :!= floor(worker_id)) | ///
        any(worker_id :< 1) | any(worker_id :> rows(worker_component))) {
        _error(3300, "panel worker identifiers do not match network membership")
    }
    st_store(., keep_variable, ///
        worker_component[worker_id] :== largest_component)
}

end
