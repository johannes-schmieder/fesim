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

real colvector fesim_network_union_labels(
    real matrix edges,
    real scalar workers,
    real scalar firms,
    real colvector active_worker,
    real colvector active_firm)
{
    real scalar component
    real scalar edge
    real scalar firm
    real scalar left
    real scalar right
    real scalar root_left
    real scalar root_right
    real scalar worker
    real colvector component_minimum
    real colvector labels
    real colvector parent
    real colvector rank

    parent = 1::(workers + firms)
    rank = J(workers + firms, 1, 0)
    for (edge = 1; edge <= rows(edges); edge++) {
        left = edges[edge, 1]
        right = workers + edges[edge, 2]
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
            if (rank[root_left] < rank[root_right]) {
                parent[root_left] = root_right
            }
            else if (rank[root_left] > rank[root_right]) {
                parent[root_right] = root_left
            }
            else {
                parent[root_right] = root_left
                rank[root_left] = rank[root_left] + 1
            }
        }
    }
    for (component = 1; component <= workers + firms; component++) {
        root_left = component
        while (parent[root_left] != root_left) {
            parent[root_left] = parent[parent[root_left]]
            root_left = parent[root_left]
        }
        parent[component] = root_left
    }

    component_minimum = J(workers + firms, 1, .)
    for (worker = 1; worker <= workers; worker++) {
        if (active_worker[worker]) {
            component = parent[worker]
            if (missing(component_minimum[component]) | ///
                worker < component_minimum[component]) {
                component_minimum[component] = worker
            }
        }
    }
    labels = J(workers + firms, 1, .)
    for (worker = 1; worker <= workers; worker++) {
        if (active_worker[worker]) {
            labels[worker] = component_minimum[parent[worker]]
        }
    }
    for (firm = 1; firm <= firms; firm++) {
        if (active_firm[firm]) {
            labels[workers + firm] = ///
                component_minimum[parent[workers + firm]]
        }
    }
    return(labels)
}

real matrix fesim_network_group_sums(
    real colvector identifiers,
    real matrix values,
    real scalar result_rows)
{
    real matrix grouped
    real matrix info
    real matrix result

    if (rows(identifiers) < 1 | rows(identifiers) != rows(values) | ///
        result_rows < 1 | result_rows != floor(result_rows)) {
        _error(3300, "network grouped-sum inputs are invalid")
    }
    grouped = sort((identifiers, values), 1)
    info = panelsetup(grouped, 1)
    result = J(result_rows, cols(values), 0)
    result[grouped[info[, 1], 1], .] = ///
        panelsum(grouped[, 2..cols(grouped)], info)
    return(result)
}

struct fesim_network_results scalar fesim_network_analyze(
    real matrix edges,
    real scalar workers,
    real scalar firms)
{
    struct fesim_network_results scalar result
    real scalar nodes
    real scalar component
    real scalar components
    real scalar largest
    real scalar candidate
    real colvector active_worker
    real colvector active_firm
    real colvector component_edges
    real colvector component_observations
    real colvector component_workers
    real colvector component_firms
    real colvector active_worker_rows
    real colvector active_firm_rows
    real colvector edge_components
    real colvector worker_components
    real colvector firm_components
    real colvector roots
    real colvector labels
    real matrix component_totals

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
        if (rows(edges) > 1 & ///
            (any(edges[2..rows(edges), 1] :< ///
                edges[1..rows(edges) - 1, 1]) | ///
            any((edges[2..rows(edges), 1] :== ///
                edges[1..rows(edges) - 1, 1]) :& ///
                (edges[2..rows(edges), 2] :<= ///
                edges[1..rows(edges) - 1, 2])))) {
            _error(3300, "network edges must be sorted and unique")
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
    active_worker = J(workers, 1, 0)
    active_firm = J(firms, 1, 0)
    active_worker_rows = uniqrows(edges[, 1])
    active_firm_rows = uniqrows(sort(edges[, 2], 1))
    active_worker[active_worker_rows] = J(rows(active_worker_rows), 1, 1)
    active_firm[active_firm_rows] = J(rows(active_firm_rows), 1, 1)
    labels = fesim_network_union_labels(
        edges, workers, firms, active_worker, active_firm)
    result.worker_component = labels[1::workers]
    result.firm_component = labels[(workers + 1)::nodes]

    edge_components = result.worker_component[edges[, 1]]
    component_totals = fesim_network_group_sums(
        edge_components, (J(rows(edges), 1, 1), edges[, 3]), nodes)
    component_edges = component_totals[, 1]
    component_observations = component_totals[, 2]
    worker_components = result.worker_component[active_worker_rows]
    component_workers = fesim_network_group_sums(
        worker_components, J(rows(worker_components), 1, 1), nodes)
    firm_components = result.firm_component[active_firm_rows]
    component_firms = fesim_network_group_sums(
        firm_components, J(rows(firm_components), 1, 1), nodes)

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

void fesim_network_store_panel(
    real scalar workers,
    real scalar firms,
    string scalar diagnostics_name,
    string scalar keep_variable,
    real scalar mark_largest)
{
    struct fesim_network_results scalar result
    real matrix boundaries
    real matrix edges
    real matrix panel
    real colvector employed
    real colvector firm_id
    real colvector keys
    real colvector starts
    real colvector unique_keys
    real colvector worker_id

    if (mark_largest != 0 & mark_largest != 1) {
        _error(3300, "network largest-component marker must be zero or one")
    }
    employed = st_data(., "employed")
    worker_id = select(st_data(., "workerid"), employed)
    firm_id = select(st_data(., "firmid"), employed)
    if (rows(worker_id) < 1) {
        _error(3300, "network panel does not contain employed observations")
    }
    if (rows(worker_id) == 1) {
        edges = (worker_id, firm_id, 1)
    }
    else if (workers <= floor(9007199254740991 / firms)) {
        keys = sort((worker_id :- 1) :* firms :+ firm_id, 1)
        boundaries = selectindex((1 \
            (keys[2..rows(keys)] :!= keys[1..rows(keys) - 1]) \
            1))
        starts = boundaries[1..rows(boundaries) - 1]
        unique_keys = keys[starts]
        edges = (floor((unique_keys :- 1) :/ firms) :+ 1, ///
            mod(unique_keys :- 1, firms) :+ 1, ///
            boundaries[2..rows(boundaries)] :- starts)
    }
    else {
        panel = sort((worker_id, firm_id), (1, 2))
        boundaries = selectindex((1 \
            ((panel[2..rows(panel), 1] :!= ///
                panel[1..rows(panel) - 1, 1]) :| ///
            (panel[2..rows(panel), 2] :!= ///
                panel[1..rows(panel) - 1, 2])) \
            1))
        starts = boundaries[1..rows(boundaries) - 1]
        edges = (panel[starts, .], ///
            boundaries[2..rows(boundaries)] :- starts)
    }
    result = fesim_network_analyze(edges, workers, firms)
    st_matrix(diagnostics_name, result.diagnostics)
    if (mark_largest) {
        worker_id = st_data(., "workerid")
        if (any(missing(worker_id)) | any(worker_id :!= floor(worker_id)) | ///
            any(worker_id :< 1) | any(worker_id :> workers)) {
            _error(3300, "panel worker identifiers do not match network membership")
        }
        st_store(., keep_variable, ///
            result.worker_component[worker_id] :== result.diagnostics[6])
    }
}

end
