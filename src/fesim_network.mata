version 16.0

mata:

real scalar fesim_network_schema_version()
{
    return(4)
}

string rowvector fesim_network_diagnostic_names()
{
    return(("components", "edges", "employed_observations", ///
        "workers", "firms", "largest_component_id", ///
        "largest_edges", "largest_observations", ///
        "largest_workers", "largest_firms", ///
        "largest_observation_share", "largest_worker_share", ///
        "largest_firm_share", "firms_no_movers", "firm_links", ///
        "edge_weight_p10", "edge_weight_p50", ///
        "edge_weight_p90", "edge_weight_p99", ///
        "articulation_firms", "graph_bridge_links"))
}

string rowvector fesim_network_leaveout_names()
{
    return(("largest_observations", "largest_workers", ///
        "largest_firms", "largest_matches", "worker_cut_vertices", ///
        "worker_set_observations", "worker_set_workers", ///
        "worker_set_firms", "worker_set_matches", ///
        "worker_set_observation_share", "worker_set_worker_share", ///
        "worker_set_firm_share", "worker_set_match_share", ///
        "vulnerable_matches_largest", ///
        "vulnerable_match_share_largest", ///
        "vulnerable_matches_worker_set", ///
        "vulnerable_match_share_worker", ///
        "worker_out_connected", "match_out_connected"))
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

real colvector fesim_network_bipartite_cut(
    real matrix edges,
    real scalar workers,
    real scalar firms)
{
    real scalar child
    real scalar active_firms
    real scalar edge
    real scalar node
    real scalar nodes
    real scalar neighbor
    real scalar root
    real scalar root_count
    real scalar time
    real scalar top
    real scalar vulnerable_matches
    real colvector active_nodes
    real colvector adjacency
    real colvector adjacency_edge
    real colvector articulation
    real colvector child_count
    real colvector cursor
    real colvector degree
    real colvector discovery
    real colvector endpoints
    real colvector low
    real colvector next_neighbor
    real colvector offset
    real colvector parent
    real colvector parent_edge
    real colvector stack
    real colvector subtree_firms
    real matrix info

    if (missing(workers) | workers < 1 | workers != floor(workers) | ///
        missing(firms) | firms < 1 | firms != floor(firms) | ///
        cols(edges) != 3) {
        _error(3300, "leave-out bipartite graph inputs are invalid")
    }
    if (!rows(edges)) return(J(workers + 1, 1, 0))
    if (any(missing(edges)) | any(edges :!= floor(edges)) | ///
        any(edges[, 1] :< 1) | any(edges[, 1] :> workers) | ///
        any(edges[, 2] :< 1) | any(edges[, 2] :> firms) | ///
        any(edges[, 3] :< 1)) {
        _error(3300, "leave-out bipartite graph edges are invalid")
    }
    if (rows(edges) > 1) {
        if (any(edges[2..rows(edges), 1] :< ///
                edges[1..rows(edges) - 1, 1]) | ///
            any((edges[2..rows(edges), 1] :== ///
                edges[1..rows(edges) - 1, 1]) :& ///
                (edges[2..rows(edges), 2] :<= ///
                edges[1..rows(edges) - 1, 2]))) {
            _error(3300, "leave-out bipartite graph edges must be sorted and unique")
        }
    }

    nodes = workers + firms
    active_firms = rows(uniqrows(sort(edges[, 2], 1)))
    endpoints = (edges[, 1] \ workers :+ edges[, 2])
    endpoints = sort(endpoints, 1)
    info = panelsetup(endpoints, 1)
    active_nodes = endpoints[info[, 1]]
    degree = J(nodes, 1, 0)
    degree[active_nodes] = info[, 2] :- info[, 1] :+ 1
    offset = J(nodes + 1, 1, 1)
    offset[2..nodes + 1] = 1 :+ runningsum(degree)
    cursor = offset[1..nodes]
    adjacency = J(2 * rows(edges), 1, .)
    adjacency_edge = J(2 * rows(edges), 1, .)
    for (edge = 1; edge <= rows(edges); edge++) {
        node = edges[edge, 1]
        neighbor = workers + edges[edge, 2]
        adjacency[cursor[node]] = neighbor
        adjacency_edge[cursor[node]] = edge
        adjacency[cursor[neighbor]] = node
        adjacency_edge[cursor[neighbor]] = edge
        cursor[node] = cursor[node] + 1
        cursor[neighbor] = cursor[neighbor] + 1
    }

    discovery = J(nodes, 1, 0)
    low = J(nodes, 1, 0)
    parent = J(nodes, 1, 0)
    parent_edge = J(nodes, 1, 0)
    child_count = J(nodes, 1, 0)
    articulation = J(nodes, 1, 0)
    next_neighbor = J(nodes, 1, 0)
    subtree_firms = (J(workers, 1, 0) \ J(firms, 1, 1))
    stack = J(rows(active_nodes), 1, 0)
    time = 0
    root_count = 0
    vulnerable_matches = 0
    for (root = 1; root <= rows(active_nodes); root++) {
        node = active_nodes[root]
        if (discovery[node] != 0) continue
        root_count = root_count + 1
        time = time + 1
        discovery[node] = time
        low[node] = time
        next_neighbor[node] = offset[node]
        top = 1
        stack[top] = node
        while (top > 0) {
            node = stack[top]
            if (next_neighbor[node] < offset[node + 1]) {
                edge = adjacency_edge[next_neighbor[node]]
                neighbor = adjacency[next_neighbor[node]]
                next_neighbor[node] = next_neighbor[node] + 1
                if (discovery[neighbor] == 0) {
                    parent[neighbor] = node
                    parent_edge[neighbor] = edge
                    child_count[node] = child_count[node] + 1
                    time = time + 1
                    discovery[neighbor] = time
                    low[neighbor] = time
                    next_neighbor[neighbor] = offset[neighbor]
                    top = top + 1
                    stack[top] = neighbor
                }
                else if (edge != parent_edge[node]) {
                    low[node] = min((low[node], discovery[neighbor]))
                }
            }
            else {
                top = top - 1
                if (parent[node] == 0) {
                    if (node <= workers & child_count[node] > 1) {
                        articulation[node] = 1
                    }
                }
                else {
                    child = node
                    node = parent[child]
                    if (node <= workers & parent[node] != 0 & ///
                        low[child] >= discovery[node]) {
                        articulation[node] = 1
                    }
                    if (low[child] > discovery[node] & ///
                        subtree_firms[child] > 0 & ///
                        subtree_firms[child] < active_firms) {
                        vulnerable_matches = vulnerable_matches + 1
                    }
                    subtree_firms[node] = subtree_firms[node] + ///
                        subtree_firms[child]
                    low[node] = min((low[node], low[child]))
                }
            }
        }
    }
    if (root_count != 1) {
        _error(3300, "leave-out bipartite graph must be connected")
    }
    return((articulation[1..workers] \ vulnerable_matches))
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

real colvector fesim_network_weight_pct(real colvector values)
{
    real scalar index
    real scalar position
    real colvector probabilities
    real colvector result
    real colvector sorted

    if (cols(values) != 1 | rows(values) < 1 | any(missing(values))) {
        _error(3300, "network percentile inputs are invalid")
    }
    sorted = sort(values, 1)
    probabilities = (.10 \.50 \.90 \.99)
    result = J(rows(probabilities), 1, .)
    for (index = 1; index <= rows(probabilities); index++) {
        position = rows(sorted) * probabilities[index]
        if (position >= 1 & position < rows(sorted) & ///
            abs(position - round(position)) < 1e-12) {
            position = round(position)
            result[index] = (sorted[position] + sorted[position + 1]) / 2
        }
        else result[index] = sorted[ceil(position)]
    }
    return(result)
}

real colvector fesim_network_articulation_stats(
    real matrix links,
    real scalar firms)
{
    real scalar bridge_links
    real scalar child
    real scalar firm
    real scalar link
    real scalar root
    real scalar time
    real scalar top
    real scalar neighbor
    real colvector active_firms
    real colvector adjacency
    real colvector articulation
    real colvector child_count
    real colvector cursor
    real colvector degree
    real colvector discovery
    real colvector endpoints
    real colvector low
    real colvector next_neighbor
    real colvector offset
    real colvector parent
    real colvector stack
    real matrix info

    if (missing(firms) | firms < 1 | firms != floor(firms) | ///
        cols(links) != 2) {
        _error(3300, "firm-graph articulation inputs are invalid")
    }
    if (!rows(links)) return((0 \ 0))
    if (any(missing(links)) | any(links :!= floor(links)) | ///
        any(links :< 1) | any(links :> firms) | ///
        any(links[, 1] :>= links[, 2])) {
        _error(3300, "firm-graph links must be sorted, unique, and unordered")
    }
    if (rows(links) > 1) {
        if (any(links[2..rows(links), 1] :< ///
            links[1..rows(links) - 1, 1]) | ///
            any((links[2..rows(links), 1] :== ///
            links[1..rows(links) - 1, 1]) :& ///
            (links[2..rows(links), 2] :<= ///
            links[1..rows(links) - 1, 2]))) {
            _error(3300, "firm-graph links must be sorted, unique, and unordered")
        }
    }

    endpoints = sort((links[, 1] \ links[, 2]), 1)
    info = panelsetup(endpoints, 1)
    active_firms = endpoints[info[, 1]]
    degree = J(firms, 1, 0)
    degree[active_firms] = info[, 2] :- info[, 1] :+ 1
    offset = J(firms + 1, 1, 1)
    offset[2..firms + 1] = 1 :+ runningsum(degree)
    cursor = offset[1..firms]
    adjacency = J(2 * rows(links), 1, .)
    for (link = 1; link <= rows(links); link++) {
        firm = links[link, 1]
        neighbor = links[link, 2]
        adjacency[cursor[firm]] = neighbor
        adjacency[cursor[neighbor]] = firm
        cursor[firm] = cursor[firm] + 1
        cursor[neighbor] = cursor[neighbor] + 1
    }

    discovery = J(firms, 1, 0)
    low = J(firms, 1, 0)
    parent = J(firms, 1, 0)
    child_count = J(firms, 1, 0)
    articulation = J(firms, 1, 0)
    next_neighbor = J(firms, 1, 0)
    stack = J(rows(active_firms), 1, 0)
    time = 0
    bridge_links = 0
    for (root = 1; root <= rows(active_firms); root++) {
        firm = active_firms[root]
        if (discovery[firm] != 0) continue
        time = time + 1
        discovery[firm] = time
        low[firm] = time
        next_neighbor[firm] = offset[firm]
        top = 1
        stack[top] = firm
        while (top > 0) {
            firm = stack[top]
            if (next_neighbor[firm] < offset[firm + 1]) {
                neighbor = adjacency[next_neighbor[firm]]
                next_neighbor[firm] = next_neighbor[firm] + 1
                if (discovery[neighbor] == 0) {
                    parent[neighbor] = firm
                    child_count[firm] = child_count[firm] + 1
                    time = time + 1
                    discovery[neighbor] = time
                    low[neighbor] = time
                    next_neighbor[neighbor] = offset[neighbor]
                    top = top + 1
                    stack[top] = neighbor
                }
                else if (neighbor != parent[firm]) {
                    low[firm] = min((low[firm], discovery[neighbor]))
                }
            }
            else {
                top = top - 1
                if (parent[firm] == 0) {
                    if (child_count[firm] > 1) articulation[firm] = 1
                }
                else {
                    child = firm
                    firm = parent[child]
                    if (parent[firm] != 0 & ///
                        low[child] >= discovery[firm]) {
                        articulation[firm] = 1
                    }
                    if (low[child] > discovery[firm]) {
                        bridge_links = bridge_links + 1
                    }
                    low[firm] = min((low[firm], low[child]))
                }
            }
        }
    }
    return((sum(articulation) \ bridge_links))
}

real colvector fesim_network_pair_stats(
    real matrix move_pairs,
    real scalar active_firms,
    real scalar firms)
{
    real colvector boundaries
    real colvector incident_firms
    real colvector link_weights
    real colvector starts
    real colvector articulation_stats
    real matrix links
    real matrix pairs

    if (cols(move_pairs) != 2 | missing(active_firms) | ///
        active_firms < 0 | active_firms != floor(active_firms) | ///
        missing(firms) | firms < 1 | firms != floor(firms) | ///
        active_firms > firms) {
        _error(3300, "network mobility-pair inputs are invalid")
    }
    if (!rows(move_pairs)) {
        return((active_firms \ 0 \ J(4, 1, .) \ 0 \ 0))
    }
    if (any(missing(move_pairs)) | ///
        any(move_pairs :!= floor(move_pairs)) | ///
        any(move_pairs :< 1) | any(move_pairs :> firms) | ///
        any(move_pairs[, 1] :== move_pairs[, 2])) {
        _error(3300, "network mobility pairs are invalid")
    }

    pairs = sort((rowmin(move_pairs), rowmax(move_pairs)), (1, 2))
    if (rows(pairs) == 1) {
        starts = 1
        link_weights = 1
    }
    else {
        boundaries = selectindex((1 \
            ((pairs[2..rows(pairs), 1] :!= ///
            pairs[1..rows(pairs) - 1, 1]) :| ///
            (pairs[2..rows(pairs), 2] :!= ///
            pairs[1..rows(pairs) - 1, 2])) \
            1))
        starts = boundaries[1..rows(boundaries) - 1]
        link_weights = boundaries[2..rows(boundaries)] :- starts
    }
    incident_firms = uniqrows(sort((pairs[starts, 1] \
        pairs[starts, 2]), 1))
    if (rows(incident_firms) > active_firms) {
        _error(3300, "network mobility pairs exceed active firms")
    }
    links = pairs[starts, .]
    articulation_stats = fesim_network_articulation_stats(links, firms)
    return((active_firms - rows(incident_firms) \
        rows(starts) \ fesim_network_weight_pct(link_weights) \
        articulation_stats))
}

real colvector fesim_network_mobility_stats(
    real colvector worker_id,
    real colvector firm_id,
    real colvector employed,
    real colvector job_to_job,
    real scalar firms)
{
    real scalar observations
    real colvector active_firms
    real colvector continuation_rows
    real colvector expected_move
    real colvector move_rows
    real colvector new_worker
    real matrix move_pairs

    observations = rows(worker_id)
    if (observations < 1 | cols(worker_id) != 1 | ///
        rows(firm_id) != observations | rows(employed) != observations | ///
        rows(job_to_job) != observations | missing(firms) | firms < 1 | ///
        firms != floor(firms) | any(missing(worker_id)) | ///
        any(worker_id :< 1) | any(worker_id :!= floor(worker_id)) | ///
        any(missing(employed)) | any((employed :!= 0) :& (employed :!= 1)) | ///
        any((firm_id :>= .) :!= (employed :== 0)) | ///
        any(select(firm_id, employed) :< 1) | ///
        any(select(firm_id, employed) :> firms) | ///
        any(select(firm_id, employed) :!= floor(select(firm_id, employed)))) {
        _error(3300, "network mobility panel inputs are invalid")
    }
    if (observations == 1) new_worker = 1
    else {
        new_worker = (1 \
            (worker_id[2..observations] :!= ///
            worker_id[1..observations - 1]))
        if (any(worker_id[2..observations] :< ///
            worker_id[1..observations - 1])) {
            _error(3300, "network mobility panel must be sorted by worker")
        }
    }
    if (any(select(job_to_job, new_worker) :< .)) {
        _error(3300, "first worker observations require missing job-to-job indicators")
    }
    continuation_rows = selectindex(new_worker :== 0)
    if (rows(continuation_rows)) {
        if (any(missing(job_to_job[continuation_rows])) | ///
            any((job_to_job[continuation_rows] :!= 0) :& ///
            (job_to_job[continuation_rows] :!= 1))) {
            _error(3300, "network job-to-job indicators are invalid")
        }
        expected_move = employed[continuation_rows] :& ///
            employed[continuation_rows :- 1] :& ///
            (firm_id[continuation_rows] :!= ///
            firm_id[continuation_rows :- 1])
        if (any(job_to_job[continuation_rows] :!= expected_move)) {
            _error(3300, "network job-to-job indicators do not match the panel")
        }
    }

    active_firms = uniqrows(sort(select(firm_id, employed), 1))
    move_rows = selectindex(job_to_job :== 1)
    if (rows(move_rows)) {
        move_pairs = (firm_id[move_rows :- 1], firm_id[move_rows])
    }
    else move_pairs = J(0, 2, .)
    return(fesim_network_pair_stats(
        move_pairs, rows(active_firms), firms))
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
        if (rows(edges) > 1) {
            if (any(edges[2..rows(edges), 1] :< ///
                    edges[1..rows(edges) - 1, 1]) | ///
                any((edges[2..rows(edges), 1] :== ///
                    edges[1..rows(edges) - 1, 1]) :& ///
                    (edges[2..rows(edges), 2] :<= ///
                    edges[1..rows(edges) - 1, 2]))) {
                _error(3300, "network edges must be sorted and unique")
            }
        }
    }

    result.schema_version = fesim_network_schema_version()
    result.diagnostics = J(21, 1, .)
    result.worker_component = J(workers, 1, .)
    result.firm_component = J(firms, 1, .)
    result.validated = 0
    if (rows(edges) == 0) {
        result.diagnostics[1..5] = (0 \ 0 \ 0 \ 0 \ 0)
        result.diagnostics[7..10] = (0 \ 0 \ 0 \ 0)
        result.diagnostics[14..15] = (0 \ 0)
        result.diagnostics[20..21] = (0 \ 0)
        result.validated = 1
        return(result)
    }
    if (rows(edges) == 1) {
        result.worker_component[edges[1, 1]] = edges[1, 1]
        result.firm_component[edges[1, 2]] = edges[1, 1]
        result.diagnostics[1..13] = (1 \ 1 \ edges[1, 3] \ 1 \ 1 \ ///
            edges[1, 1] \ 1 \ edges[1, 3] \ 1 \ 1 \ 1 \ 1 \ 1)
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

    edge_components = vec(result.worker_component[edges[, 1]])
    component_totals = fesim_network_group_sums(
        edge_components, (J(rows(edges), 1, 1), edges[, 3]), nodes)
    component_edges = component_totals[, 1]
    component_observations = component_totals[, 2]
    worker_components = vec(result.worker_component[active_worker_rows])
    component_workers = fesim_network_group_sums(
        worker_components, J(rows(worker_components), 1, 1), nodes)
    firm_components = vec(result.firm_component[active_firm_rows])
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

    result.diagnostics[1..13] = (components \ rows(edges) \ sum(edges[, 3]) \ ///
        sum(active_worker) \ sum(active_firm) \ largest \ ///
        component_edges[largest] \ component_observations[largest] \ ///
        component_workers[largest] \ component_firms[largest] \ ///
        component_observations[largest] / sum(edges[, 3]) \ ///
        component_workers[largest] / sum(active_worker) \ ///
        component_firms[largest] / sum(active_firm))
    result.validated = 1
    return(result)
}

real colvector fesim_network_leaveout(
    real matrix edges,
    real scalar workers,
    real scalar firms)
{
    struct fesim_network_results scalar base_result
    struct fesim_network_results scalar worker_result
    real colvector base_cut
    real colvector diagnostics
    real colvector worker_cut
    real matrix base_edges
    real matrix candidate_edges
    real matrix worker_edges

    diagnostics = J(19, 1, .)
    if (missing(workers) | workers < 1 | workers != floor(workers) | ///
        missing(firms) | firms < 1 | firms != floor(firms) | ///
        cols(edges) != 3) {
        _error(3300, "leave-out diagnostic inputs are invalid")
    }
    if (!rows(edges)) {
        diagnostics[1..9] = J(9, 1, 0)
        diagnostics[14] = 0
        diagnostics[16] = 0
        return(diagnostics)
    }

    base_result = fesim_network_analyze(edges, workers, firms)
    base_edges = select(edges, ///
        vec(base_result.worker_component[edges[, 1]]) :== ///
        base_result.diagnostics[6])
    base_cut = fesim_network_bipartite_cut(base_edges, workers, firms)
    diagnostics[1..5] = (base_result.diagnostics[8] \ ///
        base_result.diagnostics[9] \ base_result.diagnostics[10] \ ///
        base_result.diagnostics[7] \ sum(base_cut[1..workers]))
    diagnostics[14] = base_cut[workers + 1]
    diagnostics[15] = diagnostics[14] / diagnostics[4]

    worker_edges = base_edges
    worker_cut = base_cut
    while (sum(worker_cut[1..workers]) > 0) {
        candidate_edges = select(worker_edges, ///
            worker_cut[worker_edges[, 1]] :== 0)
        if (!rows(candidate_edges)) {
            diagnostics[6..13] = J(8, 1, 0)
            diagnostics[16] = 0
            diagnostics[18..19] = (0 \ 0)
            return(diagnostics)
        }
        worker_result = fesim_network_analyze(
            candidate_edges, workers, firms)
        worker_edges = select(candidate_edges, ///
            vec(worker_result.worker_component[candidate_edges[, 1]]) :== ///
            worker_result.diagnostics[6])
        worker_cut = fesim_network_bipartite_cut(
            worker_edges, workers, firms)
    }
    worker_result = fesim_network_analyze(worker_edges, workers, firms)
    diagnostics[6..9] = (worker_result.diagnostics[8] \ ///
        worker_result.diagnostics[9] \ worker_result.diagnostics[10] \ ///
        worker_result.diagnostics[7])
    diagnostics[10..13] = diagnostics[6..9] :/ diagnostics[1..4]
    diagnostics[16] = worker_cut[workers + 1]
    diagnostics[17] = diagnostics[16] / diagnostics[9]
    diagnostics[18] = sum(worker_cut[1..workers]) == 0
    diagnostics[19] = diagnostics[16] == 0
    return(diagnostics)
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
    string scalar leaveout_name,
    string scalar keep_variable,
    real scalar mark_largest,
    string scalar move_origin_variable,
    string scalar direct_move_variable)
{
    struct fesim_network_results scalar result
    real matrix boundaries
    real matrix edges
    real matrix move_pairs
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
    move_pairs = st_data(., ///
        (move_origin_variable, "firmid"), direct_move_variable)
    result.diagnostics[14..21] = fesim_network_pair_stats(
        move_pairs, result.diagnostics[5], firms)
    st_matrix(diagnostics_name, result.diagnostics)
    st_matrix(leaveout_name, fesim_network_leaveout(edges, workers, firms))
    if (mark_largest) {
        worker_id = st_data(., "workerid")
        if (any(missing(worker_id)) | any(worker_id :!= floor(worker_id)) | ///
            any(worker_id :< 1) | any(worker_id :> workers)) {
            _error(3300, "panel worker identifiers do not match network membership")
        }
        st_store(., keep_variable, ///
            vec(result.worker_component[worker_id]) :== result.diagnostics[6])
    }
}

end
